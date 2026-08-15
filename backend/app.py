"""FastAPI Application - Forensics Analysis Server (All 4 Parts Integrated)"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import torch
import tempfile
import os
from pathlib import Path
from typing import Optional
import uvicorn
import uuid
import json
from datetime import datetime, timezone

# Import modules
from part3_video_audio.src.models.pipeline import VideoAudioForensics, AudioDeepfakeClassifier
from part4_ensemble import EnsembleForensicsEngine, get_ensemble_engine

# Part 1: Gateway imports
try:
    import exifread
    import c2pa
    PART1_AVAILABLE = True
except ImportError:
    PART1_AVAILABLE = False
    print("⚠️ Part 1 dependencies not installed (exifread, c2pa). Running without metadata extraction.")


app = FastAPI(
    title="🔬 ForensIQ - Multimodal Forensics Platform",
    description="AI-powered forensics analysis with gateway, queuing, and comprehensive metadata extraction",
    version="2.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global instances
part1_enabled = PART1_AVAILABLE
part3_pipeline = None
ensemble_engine = None

# Part 1: Gateway Configuration
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".mp4", ".mov", ".avi", ".wav", ".mp3"}
MAX_FILE_SIZE_MB = 100

# Part 1: In-memory job storage (for production use Redis + Celery)
jobs_db = {}


@app.on_event("startup")
async def startup_event():
    """Initialize models on startup"""
    global part3_pipeline, ensemble_engine
    
    # Initialize Part 3
    try:
        face_landmarker_path = "backend/face_landmarker.task"
        if not os.path.exists(face_landmarker_path):
            raise FileNotFoundError(f"{face_landmarker_path} not found")
        
        part3_pipeline = VideoAudioForensics(landmarker_model_path=face_landmarker_path)
        print("✅ Part 3 (Video/Audio) initialized")
    except Exception as e:
        print(f"⚠️ Part 3 initialization failed: {e}")
    
    # Initialize Part 4 Ensemble
    ensemble_engine = get_ensemble_engine()
    print("✅ Part 4 (Ensemble) initialized")
    
    # Part 1 info
    if part1_enabled:
        print("✅ Part 1 (Gateway) enabled - metadata extraction available")
    else:
        print("⚠️ Part 1 (Gateway) - limited functionality (no EXIF/C2PA extraction)")


# ═══════════════════════════════════════════════════════════════════════════
# PART 1: GATEWAY, QUEUING & METADATA ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

def extract_exif_metadata(file_path: str) -> dict:
    """Extract EXIF metadata from image"""
    if not PART1_AVAILABLE:
        return {"error": "EXIF extraction not available"}
    
    try:
        with open(file_path, "rb") as f:
            tags = exifread.process_file(f, details=False)
    except Exception as e:
        return {"error": f"Could not read EXIF: {e}"}
    
    if not tags:
        return {}
    
    readable_tags = {tag: str(value) for tag, value in tags.items()}
    return {
        "camera_make": readable_tags.get("Image Make"),
        "camera_model": readable_tags.get("Image Model"),
        "software": readable_tags.get("Image Software"),
        "datetime_original": readable_tags.get("EXIF DateTimeOriginal"),
        "gps_present": any(tag.startswith("GPS") for tag in readable_tags),
        "all_tags": readable_tags,
    }


def extract_c2pa_manifest(file_path: str) -> dict:
    """Check for C2PA / Content Credentials manifest"""
    if not PART1_AVAILABLE:
        return {"has_c2pa": False}
    
    try:
        with c2pa.Reader(file_path) as reader:
            manifest_json = reader.json()
        return {"has_c2pa": True, "manifest": manifest_json}
    except c2pa.C2paError.ManifestNotFound:
        return {"has_c2pa": False}
    except Exception as e:
        return {"has_c2pa": False, "error": str(e)}


@app.post("/gateway/upload")
async def gateway_upload(file: UploadFile = File(...)):
    """
    PART 1: Accept file upload, extract metadata, queue for analysis
    
    - Validates file type and size
    - Extracts EXIF metadata
    - Checks C2PA manifest
    - Returns job_id for polling status
    """
    
    # Validate file extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type '{ext}'. Allowed: {list(ALLOWED_EXTENSIONS)}",
        )
    
    # Read and validate file size
    contents = await file.read()
    size_mb = len(contents) / (1024 * 1024)
    if size_mb > MAX_FILE_SIZE_MB:
        raise HTTPException(
            status_code=400,
            detail=f"File too large ({size_mb:.1f} MB). Max is {MAX_FILE_SIZE_MB} MB.",
        )
    
    # Generate job ID and save file
    job_id = str(uuid.uuid4())
    saved_filename = f"{job_id}{ext}"
    saved_path = os.path.join(UPLOAD_DIR, saved_filename)
    
    with open(saved_path, "wb") as f:
        f.write(contents)
    
    # Extract metadata (Part 1)
    exif_data = extract_exif_metadata(saved_path)
    c2pa_data = extract_c2pa_manifest(saved_path)
    
    # Create metadata signals for ensemble
    signals = {
        "exif_present": bool(exif_data) and "error" not in exif_data,
        "has_c2pa": c2pa_data.get("has_c2pa", False),
        "software_tag": exif_data.get("software") if exif_data else None,
        "gps_present": exif_data.get("gps_present", False) if exif_data else False,
    }
    
    # Store job in memory
    now = datetime.now(timezone.utc).isoformat()
    jobs_db[job_id] = {
        "job_id": job_id,
        "original_filename": file.filename,
        "saved_filename": saved_filename,
        "size_mb": round(size_mb, 2),
        "status": "metadata_extracted",
        "created_at": now,
        "updated_at": now,
        "exif": exif_data,
        "c2pa": c2pa_data,
        "metadata_signals": signals,
    }
    
    return {
        "job_id": job_id,
        "original_filename": file.filename,
        "saved_filename": saved_filename,
        "size_mb": round(size_mb, 2),
        "status": "metadata_extracted",
        "metadata": {
            "exif_present": signals["exif_present"],
            "has_c2pa": signals["has_c2pa"],
            "camera_model": exif_data.get("camera_model"),
        },
        "next_step": f"POST /gateway/{job_id}/analyze or GET /gateway/{job_id}/status"
    }


@app.get("/gateway/{job_id}/status")
async def gateway_status(job_id: str):
    """
    PART 1: Check job status and retrieve metadata
    """
    if job_id not in jobs_db:
        raise HTTPException(status_code=404, detail=f"No job found with id {job_id}")
    
    return jobs_db[job_id]


@app.post("/gateway/{job_id}/analyze")
async def gateway_analyze(
    job_id: str,
    file_type: str = "image",  # 'image' or 'video'
    include_part2: bool = True,
    include_part3: bool = True,
    include_part4: bool = True
):
    """
    PART 1 → PART 2/3/4: Queue file for full forensics analysis
    
    Returns metadata + proceeds to Parts 2, 3, or 4 analysis
    """
    
    if job_id not in jobs_db:
        raise HTTPException(status_code=404, detail=f"No job found with id {job_id}")
    
    job = jobs_db[job_id]
    saved_path = os.path.join(UPLOAD_DIR, job["saved_filename"])
    
    if not os.path.exists(saved_path):
        raise HTTPException(status_code=500, detail="File not found on disk")
    
    # Update status
    job["status"] = "analyzing"
    
    # Route based on file type
    if file_type == "video" and include_part3:
        # Proceed to Part 3 analysis
        if part3_pipeline is None:
            raise HTTPException(status_code=503, detail="Part 3 pipeline not initialized")
        
        try:
            video_results = part3_pipeline.run(saved_path)
            
            # Generate ensemble report (Part 4)
            report = ensemble_engine.analyze_video(
                video_path=job["original_filename"],
                video_biometrics={
                    "video_anomaly_score": video_results.get("video_anomaly_score", 0.5),
                    "ear_variance": video_results.get("ear_variance", 0),
                    "blink_blendshape_variance": video_results.get("blink_blendshape_variance", 0),
                    "head_jitter_metric": video_results.get("head_jitter_metric", 0)
                },
                audio_forensics={
                    "audio_anomaly_score": video_results.get("audio_anomaly_score", 0.5),
                    "audio_present": video_results.get("audio_present", False)
                }
            )
            
            job["status"] = "complete"
            job["analysis_result"] = report.to_dict()
            
            return job
        
        except Exception as e:
            job["status"] = "failed"
            job["error"] = str(e)
            raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
    
    else:
        job["status"] = "complete"
        return {
            "job_id": job_id,
            "message": "Metadata extracted. Awaiting Part 2/3 analysis details",
            "metadata": job["metadata_signals"]
        }


@app.get("/gateway/jobs")
async def gateway_list_jobs(limit: int = 20):
    """
    PART 1: List recent jobs
    """
    jobs_list = list(jobs_db.values())
    jobs_list.sort(key=lambda x: x["created_at"], reverse=True)
    return jobs_list[:limit]


@app.get("/health")
async def health_check():
    """Health check endpoint - all parts"""
    return {
        "status": "healthy",
        "services": {
            "part1_gateway": part1_enabled,
            "part3_pipeline": part3_pipeline is not None,
            "part4_ensemble": ensemble_engine is not None
        },
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


@app.get("/")
async def root():
    """
    ForensIQ - Complete Multimodal Forensics Platform
    All 4 Parts Integrated
    """
    return {
        "name": "🔬 ForensIQ v2.0",
        "description": "Multimodal AI-powered forensics analysis platform",
        "architecture": {
            "part1": {
                "name": "Gateway, Queuing & Metadata",
                "endpoints": [
                    "POST   /gateway/upload - Upload file & extract metadata",
                    "GET    /gateway/{job_id}/status - Check job status",
                    "POST   /gateway/{job_id}/analyze - Queue for full analysis",
                    "GET    /gateway/jobs - List recent jobs"
                ],
                "features": ["EXIF extraction", "C2PA manifest verification", "Job tracking"]
            },
            "part2": {
                "name": "Image AI & Pixel Forensics",
                "endpoints": [
                    "POST   /analyze/image - Analyze image with Track A/B/C"
                ],
                "features": ["Track A: AI-generation", "Track B: Tampering", "Track C: PRNU camera"]
            },
            "part3": {
                "name": "Video Biometrics & Audio AI",
                "endpoints": [
                    "POST   /analyze/video - Analyze video for deepfakes"
                ],
                "features": ["Eye Aspect Ratio", "Blink dynamics", "Audio deepfake detection"]
            },
            "part4": {
                "name": "Ensemble, Grad-CAM & Reports",
                "endpoints": [
                    "All analysis endpoints return structured ForensicsReport"
                ],
                "features": ["Weighted voting", "Risk assessment", "Actionable recommendations"]
            }
        },
        "documentation": "/docs",
        "status_check": "/health"
    }


# ═══════════════════════════════════════════════════════════════════════════
# PART 2/3/4: DIRECT ANALYSIS ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════


@app.post("/analyze/video")
async def analyze_video(file: UploadFile = File(...)):
    """
    Analyze video for deepfakes and biometric anomalies
    
    - **Part 3:** Video biometrics (EAR, blink patterns, head jitter)
    - **Part 3:** Audio deepfake detection (mel-spectrogram + neural classifier)
    - **Part 4:** Ensemble decision with confidence scores
    """
    
    if part3_pipeline is None:
        raise HTTPException(status_code=503, detail="Part 3 pipeline not initialized")
    
    # Save uploaded file temporarily
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
        
        # Process video
        video_results = part3_pipeline.run(tmp_path)
        
        # Generate ensemble report
        report = ensemble_engine.analyze_video(
            video_path=file.filename,
            video_biometrics={
                "video_anomaly_score": video_results.get("video_anomaly_score", 0.5),
                "ear_variance": video_results.get("ear_variance", 0),
                "blink_blendshape_variance": video_results.get("blink_blendshape_variance", 0),
                "head_jitter_metric": video_results.get("head_jitter_metric", 0)
            },
            audio_forensics={
                "audio_anomaly_score": video_results.get("audio_anomaly_score", 0.5),
                "audio_present": video_results.get("audio_present", False)
            }
        )
        
        return JSONResponse(content=report.to_dict())
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
    
    finally:
        # Clean up temp file
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


@app.post("/analyze/image")
async def analyze_image(
    file: UploadFile = File(...),
    track_a: Optional[float] = None,
    track_b: Optional[float] = None,
    track_c: Optional[float] = None
):
    """
    Analyze image using Part 2 tracks
    
    - **Track A:** AI-generation detection (GAN vs Diffusion vs Real)
    - **Track B:** Tampering & localization (Splicing, Copy-Move, Inpainting)
    - **Track C:** PRNU camera sensor verification
    - **Part 4:** Ensemble decision
    
    Query params:
    - track_a: AI-generation probability [0-1]
    - track_b: Tampering probability [0-1]
    - track_c: PRNU camera match [0-1]
    """
    
    if ensemble_engine is None:
        raise HTTPException(status_code=503, detail="Ensemble engine not initialized")
    
    if track_a is None or track_b is None or track_c is None:
        raise HTTPException(status_code=400, detail="Missing: track_a, track_b, track_c parameters")
    
    try:
        # Generate ensemble report
        report = ensemble_engine.analyze_image(
            image_path=file.filename,
            track_a_pred=track_a,
            track_b_pred=track_b,
            track_c_pred=track_c
        )
        
        return JSONResponse(content=report.to_dict())
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@app.get("/models/status")
async def models_status():
    """Check status of all models - all parts"""
    return {
        "part1": {
            "status": "enabled" if part1_enabled else "disabled",
            "features": ["EXIF extraction", "C2PA manifest verification"]
        },
        "part2": {
            "status": "Available via /analyze/image endpoint",
            "tracks": {
                "track_a": "AI-generation detection",
                "track_b": "Tampering & localization",
                "track_c": "PRNU camera verification"
            }
        },
        "part3": {
            "status": "initialized" if part3_pipeline else "not_initialized",
            "components": [
                "MediaPipe FaceLandmarker (pre-trained)",
                "AudioDeepfakeClassifier (requires training)"
            ]
        },
        "part4": {
            "status": "initialized" if ensemble_engine else "not_initialized",
            "functionality": ["Weighted voting", "Risk assessment", "Report generation"]
        }
    }


if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        reload=False
    )
