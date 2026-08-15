"""Training script for AudioDeepfakeClassifier"""

import os
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
import numpy as np
import librosa
import torchaudio.transforms as T
from pathlib import Path
from tqdm import tqdm
import json
from datetime import datetime

from ..models.pipeline import AudioDeepfakeClassifier


class AudioForensicsDataset(Dataset):
    """Dataset loader for audio forensics training"""
    
    def __init__(self, audio_dir: str, labels_file: str, sr: int = 16000, n_mels: int = 64):
        """
        Args:
            audio_dir: Directory containing audio files
            labels_file: JSON file with {filename: label} mapping (0=real, 1=deepfake)
            sr: Sample rate (default 16000 Hz)
            n_mels: Number of mel frequency bins
        """
        self.audio_dir = Path(audio_dir)
        self.sr = sr
        self.n_mels = n_mels
        
        # Load labels
        with open(labels_file, 'r') as f:
            self.labels = json.load(f)
        
        self.audio_files = list(self.labels.keys())
        
        # Mel-spectrogram transform
        self.mel_transform = T.MelSpectrogram(
            sample_rate=sr,
            n_fft=1024,
            win_length=1024,
            hop_length=512,
            n_mels=n_mels
        )
    
    def __len__(self):
        return len(self.audio_files)
    
    def __getitem__(self, idx):
        audio_file = self.audio_files[idx]
        audio_path = self.audio_dir / audio_file
        label = self.labels[audio_file]
        
        try:
            # Load audio
            y, _ = librosa.load(str(audio_path), sr=self.sr)
            
            # Truncate or pad to fixed length (8 seconds = 128000 samples)
            fixed_length = self.sr * 8
            if len(y) > fixed_length:
                y = y[:fixed_length]
            else:
                y = np.pad(y, (0, fixed_length - len(y)), mode='constant')
            
            # Convert to mel-spectrogram
            waveform = torch.tensor(y, dtype=torch.float32).unsqueeze(0)
            mel_spec = self.mel_transform(waveform)
            mel_spec_db = torch.log(mel_spec + 1e-6)  # Shape: [n_mels, time]
            
            # Add channel dimension for CNN: [1, n_mels, time]
            mel_spec_db = mel_spec_db.unsqueeze(0)
            
            return mel_spec_db, torch.tensor(label, dtype=torch.long)
        
        except Exception as e:
            print(f"Error loading {audio_file}: {e}")
            # Return silence on error
            return torch.zeros((1, self.n_mels, 251)), torch.tensor(0, dtype=torch.long)


class AudioTrainer:
    """Trainer class for AudioDeepfakeClassifier"""
    
    def __init__(self, model_save_dir: str = "outputs"):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model_save_dir = Path(model_save_dir)
        self.model_save_dir.mkdir(exist_ok=True)
        self.history = {"train_loss": [], "val_loss": [], "val_acc": []}
    
    def train(
        self,
        train_dataloader: DataLoader,
        val_dataloader: DataLoader,
        epochs: int = 20,
        learning_rate: float = 1e-3,
        model_name: str = "audio_deepfake_classifier"
    ):
        """Train the AudioDeepfakeClassifier"""
        
        model = AudioDeepfakeClassifier().to(self.device)
        criterion = nn.BCELoss()
        optimizer = optim.Adam(model.parameters(), lr=learning_rate)
        scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=5, gamma=0.5)
        
        print(f"Training on device: {self.device}")
        print(f"Epochs: {epochs} | LR: {learning_rate} | Batch size: {train_dataloader.batch_size}")
        
        for epoch in range(epochs):
            # Training phase
            model.train()
            train_loss = 0.0
            for batch_idx, (mel_specs, labels) in enumerate(tqdm(train_dataloader, desc=f"Epoch {epoch+1}/{epochs}")):
                mel_specs = mel_specs.to(self.device)
                labels = labels.float().unsqueeze(1).to(self.device)
                
                optimizer.zero_grad()
                outputs = model(mel_specs)
                loss = criterion(outputs, labels)
                loss.backward()
                optimizer.step()
                
                train_loss += loss.item()
            
            train_loss /= len(train_dataloader)
            self.history["train_loss"].append(train_loss)
            
            # Validation phase
            model.eval()
            val_loss = 0.0
            val_acc = 0.0
            with torch.no_grad():
                for mel_specs, labels in val_dataloader:
                    mel_specs = mel_specs.to(self.device)
                    labels = labels.float().unsqueeze(1).to(self.device)
                    
                    outputs = model(mel_specs)
                    loss = criterion(outputs, labels)
                    val_loss += loss.item()
                    
                    # Accuracy (threshold at 0.5)
                    preds = (outputs > 0.5).float()
                    val_acc += (preds == labels).sum().item()
            
            val_loss /= len(val_dataloader)
            val_acc /= (len(val_dataloader) * val_dataloader.batch_size)
            
            self.history["val_loss"].append(val_loss)
            self.history["val_acc"].append(val_acc)
            
            scheduler.step()
            
            print(f"Epoch {epoch+1}/{epochs} | Train Loss: {train_loss:.4f} | Val Loss: {val_loss:.4f} | Val Acc: {val_acc:.4f}")
        
        # Save model
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        model_path = self.model_save_dir / f"{model_name}_{timestamp}.pth"
        torch.save(model.state_dict(), model_path)
        print(f"\n✅ Model saved: {model_path}")
        
        # Save training history
        history_path = self.model_save_dir / f"{model_name}_{timestamp}_history.json"
        with open(history_path, 'w') as f:
            json.dump(self.history, f, indent=2)
        
        return model, model_path


def main():
    """Example training pipeline"""
    
    # Configure paths
    train_audio_dir = "data/train_audio"
    train_labels = "data/train_labels.json"
    val_audio_dir = "data/val_audio"
    val_labels = "data/val_labels.json"
    
    # Check if data exists
    if not Path(train_audio_dir).exists():
        print(f"⚠️  {train_audio_dir} not found. Please download audio datasets.")
        return
    
    # Load datasets
    print("Loading datasets...")
    train_dataset = AudioForensicsDataset(train_audio_dir, train_labels)
    val_dataset = AudioForensicsDataset(val_audio_dir, val_labels)
    
    # Create dataloaders
    train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=16, shuffle=False, num_workers=4)
    
    # Train model
    trainer = AudioTrainer(model_save_dir="outputs")
    model, model_path = trainer.train(
        train_loader,
        val_loader,
        epochs=20,
        learning_rate=1e-3,
        model_name="audio_deepfake_classifier"
    )
    
    print(f"\n✅ Training complete! Model saved at: {model_path}")


if __name__ == "__main__":
    main()
