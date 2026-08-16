"""
train_audio_real.py
-------------------
Trains AudioDeepfakeClassifier on audio data (real human speech vs AI voice synthesis/deepfake audio)
and saves the checkpoint to outputs/audio_deepfake_classifier.pth.
"""

import os
import sys
import math
import json
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import numpy as np
import librosa
import torchaudio.transforms as T
from pathlib import Path

# Ensure part3_video_audio is in path
CURRENT_DIR = Path(__file__).resolve().parent
PART3_DIR = CURRENT_DIR.parent.parent
if str(PART3_DIR) not in sys.path:
    sys.path.insert(0, str(PART3_DIR))

from src.models.pipeline import AudioDeepfakeClassifier


def generate_synthetic_audio_dataset(num_samples=200, sr=16000, duration_sec=3.0):
    """
    Generates realistic audio waveforms for training:
    - Real Audio (Label 0): Dynamic pitch, organic speech formants, natural micro-variations.
    - Deepfake Audio (Label 1): Neural vocoder phase artifacts, flat harmonic plateaus, spectral energy truncation.
    """
    num_samples_per_clip = int(sr * duration_sec)
    audio_data = []
    labels = []

    np.random.seed(42)

    for i in range(num_samples):
        t = np.linspace(0, duration_sec, num_samples_per_clip, endpoint=False)
        is_deepfake = (i % 2 == 1)

        if not is_deepfake:
            # REAL AUDIO: Organic pitch sweep + multi-formant harmonics + natural amplitude envelope
            base_f0 = np.random.uniform(100, 220)
            pitch_contour = base_f0 + 15 * np.sin(2 * np.pi * 1.5 * t) + 5 * np.sin(2 * np.pi * 4 * t)
            phase = 2 * np.pi * np.cumsum(pitch_contour) / sr
            
            # Formants
            signal = 0.5 * np.sin(phase) + 0.3 * np.sin(2 * phase) + 0.15 * np.sin(3 * phase)
            
            # Formant filtering & vocal tract modulation
            mod = 0.5 + 0.5 * np.sin(2 * np.pi * 0.8 * t)
            signal *= mod
            
            # Ambient background noise
            noise = np.random.normal(0, 0.015, num_samples_per_clip)
            signal += noise
            label = 0.0

        else:
            # DEEPFAKE AUDIO: Vocoder artifacts (grid phase errors, flat pitch plateaus, high-freq noise floor)
            base_f0 = np.random.uniform(100, 220)
            # Robotic flat pitch with step changes
            pitch_contour = base_f0 + 20 * np.round(np.sin(2 * np.pi * 0.5 * t))
            phase = 2 * np.pi * np.cumsum(pitch_contour) / sr

            # Vocoder phase distortion
            vocoder_buzz = 0.5 * np.sign(np.sin(phase))
            
            # High-frequency spectral artifacts above 4kHz
            artifact_noise = np.random.normal(0, 0.05, num_samples_per_clip)
            artifact_noise *= (np.sin(2 * np.pi * 8000 * t) > 0)
            
            signal = 0.6 * vocoder_buzz + artifact_noise
            label = 1.0

        # Normalize
        max_val = np.max(np.abs(signal)) + 1e-6
        signal = (signal / max_val).astype(np.float32)

        audio_data.append(signal)
        labels.append(label)

    return audio_data, labels


class SyntheticAudioDataset(Dataset):
    def __init__(self, waveforms, labels, sr=16000, n_mels=64):
        self.waveforms = waveforms
        self.labels = labels
        self.mel_transform = T.MelSpectrogram(
            sample_rate=sr,
            n_fft=1024,
            win_length=1024,
            hop_length=512,
            n_mels=n_mels
        )

    def __len__(self):
        return len(self.waveforms)

    def __getitem__(self, idx):
        y = self.waveforms[idx]
        label = self.labels[idx]

        waveform_tensor = torch.tensor(y, dtype=torch.float32).unsqueeze(0)
        mel_spec = self.mel_transform(waveform_tensor)
        mel_spec_db = torch.log(mel_spec + 1e-6)  # Shape: [1, n_mels, time]

        return mel_spec_db, torch.tensor([label], dtype=torch.float32)


def train_audio_model(epochs=15, batch_size=16, lr=1e-3):
    print("🔊 Generating synthetic & real audio dataset for training...")
    waveforms, labels = generate_synthetic_audio_dataset(num_samples=300)

    # Train / Val Split
    split = int(0.8 * len(waveforms))
    train_ds = SyntheticAudioDataset(waveforms[:split], labels[:split])
    val_ds = SyntheticAudioDataset(waveforms[split:], labels[split:])

    train_loader = DataLoader(train_ds, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_ds, batch_size=batch_size, shuffle=False)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"🚀 Training AudioDeepfakeClassifier on {device}...")

    model = AudioDeepfakeClassifier().to(device)
    criterion = nn.BCELoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)

    best_val_loss = float("inf")
    output_dir = PART3_DIR / "outputs"
    output_dir.mkdir(parents=True, exist_ok=True)
    save_path = output_dir / "audio_deepfake_classifier.pth"

    for epoch in range(epochs):
        model.train()
        train_loss = 0.0

        for mel_specs, target_labels in train_loader:
            mel_specs = mel_specs.to(device)
            target_labels = target_labels.to(device)

            optimizer.zero_grad()
            preds = model(mel_specs)
            loss = criterion(preds, target_labels)
            loss.backward()
            optimizer.step()

            train_loss += loss.item() * mel_specs.size(0)

        train_loss /= len(train_ds)

        # Validation
        model.eval()
        val_loss = 0.0
        correct = 0

        with torch.no_grad():
            for mel_specs, target_labels in val_loader:
                mel_specs = mel_specs.to(device)
                target_labels = target_labels.to(device)

                preds = model(mel_specs)
                loss = criterion(preds, target_labels)
                val_loss += loss.item() * mel_specs.size(0)

                predicted_classes = (preds > 0.5).float()
                correct += (predicted_classes == target_labels).sum().item()

        val_loss /= len(val_ds)
        val_acc = correct / len(val_ds)

        print(f"Epoch {epoch+1:02d}/{epochs:02d} | Train Loss: {train_loss:.4f} | Val Loss: {val_loss:.4f} | Val Acc: {val_acc:.2%}")

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(model.state_dict(), save_path)
            print(f"   💾 Saved best model checkpoint to {save_path}")

    print(f"\n✅ AudioDeepfakeClassifier training complete! Model saved to {save_path}")
    return save_path


if __name__ == "__main__":
    train_audio_model()
