"""
Training script. Run baseline first:
    python train.py --model baseline --epochs 10

Once that works end-to-end, run the dual-stream version:
    python train.py --model dual --epochs 10
"""

import argparse
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, random_split
from sklearn.metrics import roc_auc_score

from dataset import ForensicDataset
from model import BaselineNet, ForensicNet


def train(model_type="baseline", epochs=5, batch_size=8, lr=1e-4, root_dir="data"):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    full_dataset = ForensicDataset(root_dir=root_dir, train=True)
    val_size = max(1, int(0.2 * len(full_dataset)))
    train_size = len(full_dataset) - val_size
    train_ds, val_ds = random_split(full_dataset, [train_size, val_size])

    train_loader = DataLoader(train_ds, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_ds, batch_size=batch_size, shuffle=False)

    if model_type == "baseline":
        model = BaselineNet().to(device)
    else:
        model = ForensicNet().to(device)

    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-5)
    criterion = nn.CrossEntropyLoss()
    scaler = torch.cuda.amp.GradScaler(enabled=(device.type == "cuda"))

    best_auc = 0.0

    for epoch in range(epochs):
        model.train()
        total_loss = 0.0

        for rgb, residual, labels in train_loader:
            rgb, residual, labels = rgb.to(device), residual.to(device), labels.to(device)
            optimizer.zero_grad()

            with torch.cuda.amp.autocast(enabled=(device.type == "cuda")):
                if model_type == "baseline":
                    outputs = model(rgb)
                else:
                    outputs = model(rgb, residual)
                loss = criterion(outputs, labels)

            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()

            total_loss += loss.item()

        avg_loss = total_loss / len(train_loader)

        # ---- validation ----
        model.eval()
        all_probs, all_labels = [], []
        with torch.no_grad():
            for rgb, residual, labels in val_loader:
                rgb, residual = rgb.to(device), residual.to(device)
                if model_type == "baseline":
                    outputs = model(rgb)
                else:
                    outputs = model(rgb, residual)
                probs = torch.softmax(outputs, dim=1)[:, 1].cpu().numpy()
                all_probs.extend(probs)
                all_labels.extend(labels.numpy())

        try:
            auc = roc_auc_score(all_labels, all_probs)
        except ValueError:
            auc = float("nan")  # happens if val set has only one class

        print(f"Epoch {epoch+1}/{epochs} | train_loss={avg_loss:.4f} | val_auc={auc:.4f}")

        if auc > best_auc:
            best_auc = auc
            torch.save(model.state_dict(), f"best_{model_type}_model.pt")
            print(f"  -> saved best_{model_type}_model.pt (AUC={auc:.4f})")

    print(f"Training done. Best val AUC: {best_auc:.4f}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", choices=["baseline", "dual"], default="baseline")
    parser.add_argument("--epochs", type=int, default=5)
    parser.add_argument("--batch_size", type=int, default=8)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--data_dir", type=str, default="data")
    args = parser.parse_args()

    train(
        model_type=args.model,
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        root_dir=args.data_dir,
    )
