# ForensIQ - Multimodal Forensics Analysis Platform

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- CUDA 11.8+ (optional, for GPU acceleration)

### Local Development

```bash
# 1. Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Download MediaPipe Face Landmarker (already in /backend/)
# Verify: ls backend/face_landmarker.task

# 4. Train Part 3 Audio Model (Optional - skip if using pre-trained)
cd backend/part3_video_audio
python -m src.training.train_audio
# Place dataset in: data/train_audio/, data/val_audio/
# With labels in: data/train_labels.json, data/val_labels.json

# 5. Start FastAPI server
cd ../../
uvicorn backend.app:app --reload --host 0.0.0.0 --port 8000
```

Visit: `http://localhost:8000/docs` for interactive API documentation

---

## 📁 Project Structure

```
ForensIQ/
├── backend/
│   ├── app.py                          # FastAPI application
│   ├── config.py                       # Configuration
│   ├── face_landmarker.task            # Pre-trained MediaPipe model
│   │
│   ├── ai-photo-detection-main/        # Part 2: Image Forensics
│   │   ├── src/
│   │   │   ├── preprocessing/          # Dataset loading & formatting
│   │   │   ├── models/                 # Model architectures
│   │   │   ├── forensics/              # Pixel forensics features
│   │   │   ├── explainability/         # Grad-CAM visualization
│   │   │   ├── evaluation/             # Metrics & reporting
│   │   │   └── training/               # Training loops
│   │   ├── configs/                    # Model configs (YAML)
│   │   ├── models/                     # Trained model weights
│   │   └── requirements.txt
│   │
│   ├── part3_video_audio/              # Part 3: Video & Audio
│   │   ├── src/
│   │   │   ├── models/
│   │   │   │   └── pipeline.py         # VideoAudioForensics class
│   │   │   ├── training/
│   │   │   │   └── train_audio.py      # Audio model trainer
│   │   │   ├── data/                   # Training data
│   │   │   └── utils/                  # Utility functions
│   │   └── outputs/                    # Saved model weights
│   │
│   └── part4_ensemble/                 # Part 4: Ensemble & Reports
│       ├── __init__.py
│       └── ensemble_engine.py          # Voting + Report generation
│
├── Procfile                            # Render deployment config
├── runtime.txt                         # Python version for Render
├── requirements.txt                    # All dependencies
├── .gitignore
└── README.md                           # This file
```

---

## 🔧 Part 3: Train AudioDeepfakeClassifier

**Dataset Format:**
```
data/train_audio/
├── real_1.wav
├── real_2.wav
├── deepfake_1.wav
├── deepfake_2.wav
...

data/train_labels.json:
{
  "real_1.wav": 0,
  "deepfake_1.wav": 1,
  ...
}
```

**Training:**
```bash
cd backend/part3_video_audio
python -m src.training.train_audio
```

**Output:**
- Model saved: `outputs/audio_deepfake_classifier_YYYYMMDD_HHMMSS.pth`
- Training history: `outputs/audio_deepfake_classifier_YYYYMMDD_HHMMSS_history.json`

---

## 📊 API Usage

### Analyze Video
```bash
curl -X POST "http://localhost:8000/analyze/video" \
  -F "file=@video.mp4"
```

**Response:**
```json
{
  "timestamp": "2024-08-15T12:34:56.789123",
  "input_file": "video.mp4",
  "file_type": "video",
  "track_a_synthetic_prob": 0.0,
  "track_b_tampered_prob": 0.0,
  "track_c_prnu_match": 0.0,
  "video_anomaly_score": 0.1234,
  "audio_anomaly_score": 0.8765,
  "final_verdict": "AI_GENERATED",
  "confidence_score": 0.8765,
  "risk_level": "HIGH",
  "primary_indicators": [
    "Audio deepfake indicators (87.65%)"
  ],
  "secondary_indicators": [
    "Unnatural blink pattern"
  ],
  "recommendations": [
    "⚠️ Content appears to be synthetically generated",
    "Flag for fact-checking and source verification",
    "Escalate for secondary analysis"
  ]
}
```

### Analyze Image
```bash
curl -X POST "http://localhost:8000/analyze/image" \
  -F "file=@image.jpg" \
  -d "track_a=0.85&track_b=0.20&track_c=0.95"
```

---

## 🚢 Deploy to Render

1. **Push to GitHub:**
```bash
git add .
git commit -m "Add Part 3, Part 4, and FastAPI integration"
git push
```

2. **Connect to Render:**
   - Go to https://dashboard.render.com
   - New → Web Service
   - Connect GitHub repo
   - Settings:
     - **Build Command:** `pip install -r requirements.txt`
     - **Start Command:** `uvicorn backend.app:app --host 0.0.0.0 --port 8000`
     - **Environment:** Add `PYTHON_VERSION=3.10`

3. **Test:**
   - Health check: `https://your-service.onrender.com/health`
   - Docs: `https://your-service.onrender.com/docs`

---

## 🔬 Model Components

### Part 2: Image AI & Pixel Forensics
- **Track A:** Synthetic media detection (REAL vs AI-GENERATED)
  - Detects: GAN, Diffusion, DALL-E, Midjourney
  - Methods: Fourier analysis, VAE anomalies, checkerboard artifacts
  
- **Track B:** Image tampering & localization (REAL vs MANIPULATED)
  - Detects: Splicing, Copy-Move, Inpainting
  - Output: Binary tampering mask
  
- **Track C:** PRNU camera sensor verification
  - Reference: RAISE-1k (Nikon D7000, D90, D40)
  - Metric: Peak-to-Correlation Energy (PCE)

### Part 3: Video Biometrics & Audio AI
- **Video Biometrics:**
  - Eye Aspect Ratio (EAR) for blink dynamics
  - Head jitter detection
  - Face landmark tracking via MediaPipe
  
- **Audio Deepfake Detection:**
  - Mel-spectrogram feature extraction
  - Neural classifier (CNN backbone)
  - Spectral flatness & MFCC analysis

### Part 4: Ensemble & Reports
- **Weighted Voting:**
  - Track A: 25% weight
  - Track B: 25% weight
  - Track C: 15% weight
  - Video: 20% weight
  - Audio: 15% weight
  
- **Output:** Structured JSON report with:
  - Final verdict (AUTHENTIC, AI_GENERATED, TAMPERED, UNKNOWN)
  - Confidence score
  - Risk level (LOW, MEDIUM, HIGH, CRITICAL)
  - Primary/secondary indicators
  - Actionable recommendations

---

## 📝 Example Report

```json
{
  "timestamp": "2024-08-15T12:34:56",
  "input_file": "suspect_video.mp4",
  "file_type": "video",
  "final_verdict": "AI_GENERATED",
  "confidence_score": 0.8765,
  "risk_level": "CRITICAL",
  "primary_indicators": [
    "Audio deepfake indicators (87.65%)",
    "Video biometric anomalies detected (52.10%)"
  ],
  "recommendations": [
    "🚨 URGENT: Escalate to forensics specialist",
    "Preserve all original file bytes",
    "Flag for fact-checking and source verification"
  ]
}
```

---

## 🐛 Troubleshooting

### Error: `face_landmarker.task not found`
```bash
# Re-download the model
curl -o backend/face_landmarker.task \
  https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task
```

### Error: `AudioDeepfakeClassifier weights not found`
```bash
# Train the model first
cd backend/part3_video_audio
python -m src.training.train_audio
```

### GPU Memory Issues
```python
# In app.py, modify startup_event():
import torch
torch.cuda.empty_cache()
torch.set_num_threads(4)  # Limit threads
```

---

## 📚 References

- [MediaPipe FaceLandmarker](https://developers.google.com/mediapipe/solutions/vision/face_landmarker)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Render Deployment Guide](https://render.com/docs)
- [PyTorch Audio Forensics](https://pytorch.org/audio/)

---

## 📄 License

This project is for research and forensics purposes. Use responsibly.

---

**Last Updated:** August 15, 2024
