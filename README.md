# 🔬 ForensIQ v1.0 - Multimodal Deepfake & Digital Media Authenticity Verification Platform

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104.1-green.svg)](https://fastapi.tiangolo.com/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.2.0%2B-ee4c2c.svg)](https://pytorch.org/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)]()

> **Problem Statement Set – 1: Deepfake & Digital Media Authenticity Verification**  
> *A unified AI/ML and digital forensics platform engineered to detect synthetic images, manipulated videos, and AI-generated voices. Provides verifiable confidence scores, risk level assessments, visual explainability heatmaps, C2PA content provenance validation, and automated forensic audit PDF reports.*

---

## 🚀 Quick Start

### 1. Prerequisites
- **Python**: `3.10` or higher
- **FFmpeg**: Required for video frame extraction and audio track separation
- **Optional**: Redis (for Celery task queuing) & CUDA 11.8+ (for GPU acceleration)

### 2. Local Environment Setup

```bash
# Clone and enter directory
cd /Users/yashmalhotra/Documents/Spidey\ AI

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install core dependencies
pip install -r requirements.txt
```

### 3. Run Backend Verification Suite

```bash
# Execute end-to-end unit tests verifying all modules and API routes
./venv/bin/python backend/test_backend_models.py
```

### 4. Start the ForensIQ Platform Server

```bash
# Start FastAPI application with live reloading
uvicorn backend.app:app --host 0.0.0.0 --port 8000
```

- **Interactive API Documentation (Swagger UI)**: `http://localhost:8000/docs`
- **ReDoc Technical Docs**: `http://localhost:8000/redoc`

---

## 📊 System Architecture

```
                          ┌────────────────────────────────────────────────────────┐
                          │            GATEWAY & METADATA EXTRACTION               │
                          │   • File Validation (Type/Size)   • EXIF Extraction    │
                          │   • C2PA Manifest Reader          • Redis/Celery Queue │
                          └───────────────────────────┬────────────────────────────┘
                                                      │
                                          job_id & metadata signals
                                                      │
               ┌──────────────────────────────────────┼──────────────────────────────────────┐
               │                                      │                                      │
 ┌─────────────▼──────────────┐         ┌─────────────▼──────────────┐         ┌─────────────▼──────────────┐
 │   IMAGE FORENSICS ENGINE   │         │   VIDEO & AUDIO FORENSICS  │         │  DIRECT MODALITY UPLOAD    │
 │  (deepfake-detector-main)  │         │      (part3_video_audio)   │         │ (Images / Videos / Audio)  │
 │                            │         │                            │         │                            │
 │ • BaselineNet & ForensicNet│         │ • MediaPipe FaceLandmarker │         │ • POST /analyze/image      │
 │   (timm EfficientNet-b0)   │         │   (EAR, Blinks, Head Jitter)│        │ • POST /analyze/video      │
 │ • Error Level Analysis     │         │ • FFmpeg Audio Extraction  │         │ • POST /analyze/deepfake   │
 │ • 2D FFT Spectral Analysis │         │ • Mel-Spectrogram +        │         │                            │
 │ • High-Freq Noise Residual │         │   AudioDeepfakeClassifier  │         │                            │
 └─────────────┬──────────────┘         └─────────────┬──────────────┘         └─────────────┬──────────────┘
               │                                      │                                      │
     Track A / B / C Scores                 Video & Audio Anomaly                  Modality Scores
               │                                      │                                      │
               └──────────────────────────────────────┼──────────────────────────────────────┘
                                                      │
                                       ┌──────────────▼──────────────┐
                                       │   MULTIMODAL ENSEMBLE ENGINE │
                                       │    (ensemble & deepfake)    │
                                       │                             │
                                       │ • Weighted Soft Voting      │
                                       │ • Meta-Classifier Fusion    │
                                       │ • PyTorch-GradCAM Heatmaps  │
                                       │ • Risk Level Assessment     │
                                       │ • Actionable Recommendations│
                                       └──────────────┬──────────────┘
                                                      │
                                       ┌──────────────▼──────────────┐
                                       │      FINAL DELIVERABLES     │
                                       │  • Structured JSON Report   │
                                       │  • ReportLab PDF Audit Doc  │
                                       └─────────────────────────────┘
```

---

## 🛠 Complete Module Breakdown

### 📦 Gateway, Queuing & Metadata
- **Primary Libraries**: `FastAPI`, `Celery`, `Redis`, `c2pa-python`, `exifread`
- **Features**:
  - Validates uploads against file extension allowlists (`.jpg`, `.png`, `.mp4`, `.wav`, `.mp3`) and file size limits (100MB).
  - Extracts camera metadata (Make, Model, Software, GPS) via `exifread`.
  - Parses C2PA Content Credentials provenance manifests (`c2pa-python`) to verify digital signature authenticity.
  - Asynchronous background job queue backed by `Celery` + `Redis`.

### 🖼 Image AI & Pixel Forensics (`deepfake-detector-main`)
- **Primary Libraries**: `PyTorch`, `OpenCV`, `timm`, `NumPy`, `SciPy`
- **Features**:
  - **Neural Backbones**: `BaselineNet` (single-stream EfficientNet-b0 via `timm`) and `ForensicNet` (dual-stream RGB + Noise Residual fusion).
  - **Classical Pixel Forensics**:
    - **Track A (AI Generation)**: 2D FFT log-magnitude spectral analysis detecting high-frequency periodic grid artifacts left by GANs/Diffusion models.
    - **Track B (Tampering & Splicing)**: Error Level Analysis (ELA) measuring JPEG re-compression rate variances across image regions.
    - **Track C (PRNU Sensor Verification)**: Denoised high-frequency noise residual standard deviation measuring camera sensor fingerprint consistency.

### 🎥 Video Biometrics & Audio AI (`part3_video_audio`)
- **Primary Libraries**: `ffmpeg-python`, `MediaPipe`, `librosa`, `torchaudio`
- **Features**:
  - **Video Biometrics**: Facial landmark tracking via `MediaPipe` `FaceLandmarker` analyzing Eye Aspect Ratio (EAR), blink variance dynamics, and erratic head jitter.
  - **Audio Track Extraction**: Automated 16kHz mono audio extraction using `ffmpeg-python`.
  - **Voice Deepfake Detection**: Audio Spectrogram conversion using `torchaudio.transforms.MelSpectrogram` passed into PyTorch `AudioDeepfakeClassifier` CNN model.

### 📊 Ensemble Engine, Explainability & PDF Reports (`part4_ensemble` & `deepfake`)
- **Primary Libraries**: `PyTorch-GradCAM`, `ReportLab`, `Pydantic`, `scikit-learn`
- **Features**:
  - **Ensemble Fusion**: Weighted soft-voting scheme and `scikit-learn` `LogisticRegression` meta-classifier fusing multimodal probabilities.
  - **Visual Explainability**: `pytorch-grad-cam` layer heatmaps highlighting tampered or synthetic image regions.
  - **PDF Audit Generation**: `ReportLab` engine compiling structured forensic audit documentation containing confidence metrics, indicators, and recommendations.

---

## 🔌 API Reference & Usage Examples

### 1. Gateway Upload & Metadata Extraction
```bash
curl -X POST "http://localhost:8000/gateway/upload" \
  -F "file=@suspect_image.jpg"
```
**Response:**
```json
{
  "job_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "original_filename": "suspect_image.jpg",
  "saved_filename": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d.jpg",
  "size_mb": 1.25,
  "status": "metadata_extracted",
  "metadata": {
    "exif_present": true,
    "has_c2pa": false,
    "camera_model": "iPhone 13 Pro"
  },
  "next_step": "POST /gateway/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d/analyze"
}
```

### 2. Direct Image Analysis
```bash
curl -X POST "http://localhost:8000/analyze/image" \
  -F "file=@sample_photo.jpg"
```
**Response:**
```json
{
  "timestamp": "2026-08-16T17:23:00.123456",
  "input_file": "sample_photo.jpg",
  "file_type": "image",
  "track_a_synthetic_prob": 0.1520,
  "track_b_tampered_prob": 0.0840,
  "track_c_prnu_match": 0.9200,
  "final_verdict": "AUTHENTIC",
  "confidence_score": 0.8480,
  "risk_level": "LOW",
  "primary_indicators": [],
  "secondary_indicators": [],
  "recommendations": [
    "✓ Content appears authentic",
    "No major forensic red flags detected"
  ]
}
```

### 3. Deepfake Score Fusion & PDF Report Generation
```bash
curl -X POST "http://localhost:8000/analyze/deepfake" \
  -F "file=@deepfake_video.mp4"
```
**Response:**
```json
{
  "status": "success",
  "input_file": "deepfake_video.mp4",
  "fusion": {
    "fused_score": 0.8850,
    "verdict": "MANIPULATED"
  },
  "pdf_report": "/Users/yashmalhotra/Documents/Spidey AI/backend/deepfake/outputs/deepfake_4e611ca5.pdf",
  "source": "deepfake"
}
```

---

## 📁 Repository Structure

```
Spidey AI/
├── backend/
│   ├── Part-1/                         # Gateway & Metadata Service
│   │   ├── main.py                     # Standalone FastAPI gateway
│   │   ├── celery_app.py               # Redis/Celery queue setup
│   │   ├── tasks.py                    # Metadata background tasks
│   │   └── db.py                       # SQLite job history
│   │
│   ├── deepfake-detector-main/         # Image AI & Pixel Forensics Engine
│   │   ├── model.py                    # BaselineNet & ForensicNet (timm EfficientNet-b0)
│   │   ├── forensics.py                # ELA, noise residual, 2D FFT spectrum
│   │   ├── predict.py                  # Predict & multi-track scoring (Track A/B/C)
│   │   ├── dataset.py                  # PyTorch Dataset loader
│   │   └── train.py                    # Model training loop
│   │
│   ├── part3_video_audio/              # Video Biometrics & Audio AI
│   │   ├── src/models/pipeline.py      # MediaPipe FaceLandmarker + PyTorch AudioClassifier
│   │   └── src/training/train_audio.py # Audio deepfake training pipeline
│   │
│   ├── part4_ensemble/                 # Multi-Track Ensemble Engine
│   │   └── __init__.py                 # EnsembleForensicsEngine & ForensicsReport
│   │
│   ├── deepfake/                       # Multimodal Fusion & Report Generation
│   │   ├── score_fusion.py             # Weighted soft-voting & meta-classifier
│   │   ├── gradcam_module.py           # PyTorch-GradCAM explainability
│   │   ├── report_generator.py         # ReportLab PDF report generation
│   │   └── schemas.py                  # Pydantic data schemas
│   │
│   ├── app.py                          # ⭐ Unified Main FastAPI Server
│   ├── config.py                       # Configuration & environment variables
│   ├── test_backend_models.py          # End-to-end system test suite
│   └── face_landmarker.task            # Pre-trained MediaPipe landmark model
│
├── frontend/                           # Web user interface components
├── requirements.txt                    # Unified dependency specification
├── Procfile                            # Render deployment specification
├── runtime.txt                         # Python runtime version (3.10.13)
└── README.md                           # Documentation
```

---

## 🧪 Testing & Verification

The system includes an end-to-end verification script testing every sub-module and API endpoint:

```bash
./venv/bin/python backend/test_backend_models.py
```

**Test Coverage**:
- ✅ Model Initialization (MediaPipe FaceLandmarker, PyTorch AudioDeepfakeClassifier, Image ForensicNet, Ensemble Engine).
- ✅ Image Forensics Feature Extraction (ELA, Noise Residuals, 2D FFT).
- ✅ Audio Feature Conversion (Spectrogram, MFCC variance, Neural Audio Score).
- ✅ FastAPI Endpoints (`/health`, `/models/status`, `/analyze/image`, `/analyze/deepfake`).
- ✅ PDF Audit Report Generation (`ReportLab`).

---

## 🤝 Problem Statement Compliance Checklist

| Requirement | Platform Implementation | Status |
| :--- | :--- | :---: |
| **Detect manipulated images** | `deepfake-detector-main` Error Level Analysis + Noise Residual Splicing Detection | ✅ |
| **Detect AI-generated synthetic images** | `deepfake-detector-main` `BaselineNet` / `ForensicNet` + 2D FFT Spectral Grid Analysis | ✅ |
| **Detect deepfake videos** | `MediaPipe` FaceLandmarker (Eye Aspect Ratio, blink dynamics, head jitter) | ✅ |
| **Detect AI-generated voices** | `torchaudio` MelSpectrogram + PyTorch `AudioDeepfakeClassifier` | ✅ |
| **Metadata & Provenance Verification** | `exifread` camera metadata + `c2pa-python` Content Credentials manifest verification | ✅ |
| **Provide confidence score & verdict** | `EnsembleForensicsEngine` weighted soft-vote / meta-classifier scoring (`0.0 - 1.0`) | ✅ |
| **User actionable report** | Structured JSON API output + PDF forensic audit documentation (`ReportLab`) | ✅ |

---

## 📝 License & Attribution

Designed and developed for **Problem Statement Set – 1 (Deepfake & Digital Media Authenticity Verification)**.  
Built using PyTorch, OpenCV, MediaPipe, FastAPI, timm, ReportLab, and Scikit-Learn.
