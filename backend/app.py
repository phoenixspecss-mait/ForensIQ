"""FastAPI Application - Forensics Analysis Server"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import torch
import tempfile
import os
from pathlib import Path
from typing import Optional
import uvicorn

# Import modules
from part3_video_audio.src.models.pipeline import VideoAudioForensics, AudioDeepfakeClassifier
from part4_ensemble import EnsembleForensicsEngine, get_ensemble_engine


app = FastAPI(
    title="🔬 ForensIQ - Multimodal Forensics API",
    description="AI-powered forensics analysis for images and videos",
    version="1.0.0"
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
part3_pipeline = None
ensemble_engine = None


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


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "services": {
            "part3_pipeline": part3_pipeline is not None,
            "ensemble_engine": ensemble_engine is not None
        }
    }


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
    """Check status of all models"""
    return {
        "part2": {
            "status": "Available via track_a, track_b, track_c endpoints",
            "requires": "Model predictions from part2 (ai-photo-detection-main)"
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
            "functionality": "Ensemble voting + Report generation"
        }
    }


@app.get("/")
async def root():
    """API documentation"""
    return {
        "app": "ForensIQ - Multimodal Forensics API",
        "version": "1.0.0",
        "endpoints": {
            "POST /analyze/video": "Analyze video for deepfakes",
            "POST /analyze/image": "Analyze image with Part 2 predictions",
            "GET /health": "Health check",
            "GET /models/status": "Check model status"
        },
        "docs": "/docs"
    }


if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        reload=False
    )
