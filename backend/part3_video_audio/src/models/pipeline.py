import os
import cv2
import torch
import torch.nn as nn
import numpy as np
import ffmpeg
import librosa
import torchaudio.transforms as T
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# -------------------------------------------------------------
# 1. Neural Audio Classifier Backbone (PyTorch + Torchaudio)
# -------------------------------------------------------------
class AudioDeepfakeClassifier(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(1, 32, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(32, 64, kernel_size=3, stride=1, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.AdaptiveAvgPool2d((4, 4))
        )
        self.fc = nn.Sequential(
            nn.Linear(64 * 4 * 4, 64),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(64, 1),
            nn.Sigmoid()
        )

    def forward(self, x):
        x = self.conv(x)
        x = torch.flatten(x, 1)
        return self.fc(x)

# -------------------------------------------------------------
# 2. Comprehensive Multimodal Forensic Pipeline
# -------------------------------------------------------------
class VideoAudioForensics:
    def __init__(self, landmarker_model_path: str = "face_landmarker.task"):
        base_options = python.BaseOptions(model_asset_path=landmarker_model_path)
        self.landmarker_options = vision.FaceLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.VIDEO,
            num_faces=1,
            output_face_blendshapes=True
        )
        
        # Audio Spectrogram Transform
        self.mel_transform = T.MelSpectrogram(
            sample_rate=16000,
            n_fft=1024,
            win_length=1024,
            hop_length=512,
            n_mels=64
        )
        self.audio_model = AudioDeepfakeClassifier()
        weights_path = os.path.join(os.path.dirname(__file__), "..", "..", "outputs", "audio_deepfake_classifier.pth")
        if os.path.exists(weights_path):
            try:
                self.audio_model.load_state_dict(torch.load(weights_path, map_location="cpu"))
                print(f"✅ Loaded trained AudioDeepfakeClassifier weights from {weights_path}")
            except Exception as e:
                print(f"⚠️ Failed to load AudioDeepfakeClassifier weights: {e}")
        else:
            print(f"⚠️ AudioDeepfakeClassifier checkpoint not found at {weights_path}, running default model")
        self.audio_model.eval()

    def _calculate_ear(self, landmarks) -> float:
        """Computes Eye Aspect Ratio (EAR) for blink dynamics."""
        # Standard 468/478 landmark indices for left and right eyes
        # Left eye: Top (159), Bottom (145), Left (33), Right (133)
        p_top = np.array([landmarks[159].x, landmarks[159].y])
        p_bottom = np.array([landmarks[145].x, landmarks[145].y])
        p_left = np.array([landmarks[33].x, landmarks[33].y])
        p_right = np.array([landmarks[133].x, landmarks[133].y])

        v_dist = np.linalg.norm(p_top - p_bottom)
        h_dist = np.linalg.norm(p_left - p_right) + 1e-6
        return float(v_dist / h_dist)

    def extract_audio(self, video_path: str, output_wav: str = "temp_audio.wav") -> str:
        """Extracts 16kHz mono audio track via ffmpeg-python."""
        try:
            (
                ffmpeg
                .input(video_path)
                .output(output_wav, ac=1, ar=16000, loglevel="quiet")
                .overwrite_output()
                .run()
            )
            return output_wav if os.path.exists(output_wav) else ""
        except ffmpeg.Error:
            return ""

    def process_video_biometrics(self, video_path: str) -> dict:
        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
        frame_idx = 0

        ear_history = []
        blendshape_blink_history = []
        nose_tip_positions = []

        with vision.FaceLandmarker.create_from_options(self.landmarker_options) as landmarker:
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break

                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
                timestamp_ms = int((frame_idx / fps) * 1000)
                
                result = landmarker.detect_for_video(mp_image, timestamp_ms)

                if result.face_landmarks:
                    landmarks = result.face_landmarks[0]
                    ear_history.append(self._calculate_ear(landmarks))
                    nose_tip_positions.append([landmarks[1].x, landmarks[1].y, landmarks[1].z])

                if result.face_blendshapes:
                    b_dict = {b.category_name: b.score for b in result.face_blendshapes[0]}
                    avg_blink = (b_dict.get("eyeBlinkLeft", 0.0) + b_dict.get("eyeBlinkRight", 0.0)) / 2.0
                    blendshape_blink_history.append(avg_blink)

                frame_idx += 1

        cap.release()

        # Compute biometric dynamics
        ear_variance = float(np.var(ear_history)) if len(ear_history) > 1 else 0.0
        blendshape_blink_var = float(np.var(blendshape_blink_history)) if len(blendshape_blink_history) > 1 else 0.0
        
        # Head jitter detection (rapid erratic movement of nose tip between consecutive frames)
        if len(nose_tip_positions) > 2:
            deltas = np.diff(np.array(nose_tip_positions), axis=0)
            jitter_score = float(np.mean(np.linalg.norm(deltas, axis=1)))
        else:
            jitter_score = 0.0

        # Anomaly scoring
        is_blink_frozen = len(blendshape_blink_history) > 30 and blendshape_blink_var < 0.002
        is_jitter_high = jitter_score > 0.05
        
        video_fake_prob = 0.85 if (is_blink_frozen or is_jitter_high) else 0.15

        return {
            "frames_analyzed": frame_idx,
            "ear_variance": round(ear_variance, 6),
            "blink_blendshape_variance": round(blendshape_blink_var, 6),
            "head_jitter_metric": round(jitter_score, 6),
            "video_anomaly_score": video_fake_prob
        }

    def process_audio_ai(self, audio_path: str) -> dict:
        if not audio_path or not os.path.exists(audio_path):
            return {"audio_present": False, "audio_anomaly_score": 0.50}

        y, sr = librosa.load(audio_path, sr=16000)
        if len(y) < sr * 0.5:
            return {"audio_present": False, "audio_anomaly_score": 0.50}

        # 1. Torchaudio Mel-Spectrogram Extraction
        waveform_tensor = torch.tensor(y, dtype=torch.float32).unsqueeze(0)
        mel_spec = self.mel_transform(waveform_tensor)
        mel_spec_db = torch.log(mel_spec + 1e-6).unsqueeze(0)  # Shape: [1, 1, n_mels, time]

        # 2. Neural Audio Model Inference
        with torch.no_grad():
            nn_fake_prob = float(self.audio_model(mel_spec_db).item())

        # 3. Librosa DSP Forensic Checks (Spectral Flatness & MFCC Variance)
        flatness = float(np.mean(librosa.feature.spectral_flatness(y=y)))
        mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
        mfcc_var = float(np.mean(np.var(mfccs, axis=1)))

        # Blended DSP + Neural Score
        dsp_penalty = 0.3 if (flatness < 0.0001 or mfcc_var < 40.0) else 0.0
        final_audio_score = min(0.95, round(0.6 * nn_fake_prob + dsp_penalty, 4))

        return {
            "audio_present": True,
            "spectral_flatness": round(flatness, 6),
            "mfcc_variance": round(mfcc_var, 4),
            "neural_audio_score": round(nn_fake_prob, 4),
            "audio_anomaly_score": final_audio_score
        }

    def run(self, video_path: str) -> dict:
        video_biometrics = self.process_video_biometrics(video_path)
        
        temp_audio = f"temp_{os.path.basename(video_path)}.wav"
        extracted_audio = self.extract_audio(video_path, temp_audio)
        audio_forensics = self.process_audio_ai(extracted_audio)

        if os.path.exists(temp_audio):
            os.remove(temp_audio)

        # Multimodal fusion
        v_score = video_biometrics["video_anomaly_score"]
        a_score = audio_forensics["audio_anomaly_score"]
        part3_score = round(0.65 * v_score + 0.35 * a_score, 4)

        return {
            "part3_anomaly_score": part3_score,
            "verdict": "Manipulated / Deepfake" if part3_score > 0.50 else "Authentic / Real",
            "video_biometrics": video_biometrics,
            "audio_forensics": audio_forensics
        }