"""Render Deployment Configuration"""

import os

# Server config
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))
DEBUG = os.getenv("DEBUG", "false").lower() == "true"
RELOAD = os.getenv("RELOAD", "false").lower() == "true"

# Model paths
FACE_LANDMARKER_PATH = os.getenv("FACE_LANDMARKER_PATH", "backend/face_landmarker.task")
AUDIO_MODEL_PATH = os.getenv("AUDIO_MODEL_PATH", "backend/part3_video_audio/outputs/audio_deepfake_classifier.pth")
PART2_MODEL_PATH = os.getenv("PART2_MODEL_PATH", "backend/ai-photo-detection-main/models/")

# GPU/Device
USE_GPU = os.getenv("USE_GPU", "true").lower() == "true"

# API limits
MAX_FILE_SIZE_MB = int(os.getenv("MAX_FILE_SIZE_MB", 100))
MAX_VIDEO_DURATION_SEC = int(os.getenv("MAX_VIDEO_DURATION_SEC", 600))

print(f"""
╔════════════════════════════════════════════╗
║    ForensIQ Configuration                  ║
╠════════════════════════════════════════════╣
║ Host: {HOST:<33} ║
║ Port: {PORT:<33} ║
║ Face Landmarker: {FACE_LANDMARKER_PATH:<20} ║
║ GPU Enabled: {str(USE_GPU):<26} ║
╚════════════════════════════════════════════╝
""")
