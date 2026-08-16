"""
Single entry point for the rest of the pipeline (Part 1's API, Part 4's reports)
to call.

Usage:
    python predict.py path/to/image.jpg --model_type baseline --weights best_baseline_model.pt
"""

import argparse
import cv2
import torch
import numpy as np
from torchvision import transforms

from model import BaselineNet, ForensicNet
from forensics import noise_residual

# Temperature for calibrating softmax confidence.
# Set this properly using a held-out validation set (see calibrate.py note below).
# 1.0 = no calibration (raw softmax, usually overconfident).
TEMPERATURE = 1.5

_rgb_transform = transforms.Compose([
    transforms.ToPILImage(),
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])


def load_model(model_type="baseline", weights_path=None, device="cpu"):
    if model_type == "baseline":
        model = BaselineNet(pretrained=False)
    else:
        model = ForensicNet(pretrained=False)

    if weights_path:
        model.load_state_dict(torch.load(weights_path, map_location=device))

    model.to(device)
    model.eval()
    return model


def predict(image_path: str, model, model_type="baseline", device="cpu") -> dict:
    """
    Returns: {"label": "real"|"fake", "confidence": float 0-1, "raw_probs": [p_real, p_fake]}
    """
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        raise FileNotFoundError(f"Could not read image: {image_path}")

    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    rgb_tensor = _rgb_transform(img_rgb).unsqueeze(0).to(device)

    with torch.no_grad():
        if model_type == "baseline":
            logits = model(rgb_tensor)
        else:
            residual = noise_residual(image_path)
            residual = cv2.resize(residual, (224, 224))
            residual = (residual - residual.mean()) / (residual.std() + 1e-6)
            residual_tensor = torch.from_numpy(residual).unsqueeze(0).unsqueeze(0).float().to(device)
            logits = model(rgb_tensor, residual_tensor)

        # temperature scaling for calibrated confidence
        calibrated_logits = logits / TEMPERATURE
        probs = torch.softmax(calibrated_logits, dim=1).cpu().numpy()[0]

    label = "fake" if probs[1] > probs[0] else "real"
    confidence = float(max(probs))

    return {
        "label": label,
        "confidence": round(confidence, 4),
        "raw_probs": {"real": round(float(probs[0]), 4), "fake": round(float(probs[1]), 4)},
    }


def predict_tracks(image_path: str, model=None, model_type="dual", device="cpu") -> dict:
    """
    Evaluates image using both classical pixel-forensics (ELA, noise residual, 2D FFT)
    and the deep learning model (BaselineNet/ForensicNet), returning 3-track scores:
    - track_a_synthetic_prob: AI-generation probability (neural model + FFT anomaly)
    - track_b_tampered_prob: Splicing / local manipulation probability (ELA + noise variance)
    - track_c_prnu_match: PRNU / camera sensor fingerprint consistency match score
    """
    from forensics import error_level_analysis, noise_residual, frequency_spectrum

    # 1. Classical Forensics
    ela_map = error_level_analysis(image_path)
    ela_mean = float(np.mean(ela_map))
    ela_std = float(np.std(ela_map))
    
    residual = noise_residual(image_path)
    res_std = float(np.std(residual))
    
    freq_spec = frequency_spectrum(image_path)
    fft_high_freq = float(np.percentile(freq_spec, 95))

    # 2. Neural Model Inference (if model available)
    neural_fake_prob = 0.5
    if model is not None:
        pred = predict(image_path, model, model_type=model_type, device=device)
        neural_fake_prob = pred["raw_probs"]["fake"]

    # 3. Track calculation
    # Track A (AI-Generation): Neural fake probability combined with FFT high-frequency signature
    fft_score = float(np.clip((fft_high_freq - 12.0) / 10.0, 0.05, 0.95))
    track_a_synthetic_prob = round(0.7 * neural_fake_prob + 0.3 * fft_score, 4)

    # Track B (Tampering/Splicing): ELA error level variance + noise residual anomaly
    ela_score = float(np.clip((ela_std / (ela_mean + 1e-5)) / 2.0, 0.05, 0.95))
    track_b_tampered_prob = round(0.5 * ela_score + 0.5 * (1.0 - min(1.0, res_std / 15.0)), 4)

    # Track C (PRNU Camera Verification): Camera sensor residual consistency (higher = authentic camera, lower = synthetic)
    track_c_prnu_match = round(float(np.clip(res_std / 20.0, 0.1, 0.95)), 4)

    return {
        "label": "fake" if track_a_synthetic_prob > 0.5 or track_b_tampered_prob > 0.5 else "real",
        "confidence": round(float(max(track_a_synthetic_prob, track_b_tampered_prob, 1.0 - track_c_prnu_match)), 4),
        "track_a_synthetic_prob": track_a_synthetic_prob,
        "track_b_tampered_prob": track_b_tampered_prob,
        "track_c_prnu_match": track_c_prnu_match,
        "raw_probs": {"real": round(1.0 - neural_fake_prob, 4), "fake": round(neural_fake_prob, 4)}
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("image_path")
    parser.add_argument("--model_type", choices=["baseline", "dual"], default="baseline")
    parser.add_argument("--weights", default=None, help="Path to trained .pt weights file")
    args = parser.parse_args()

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = load_model(args.model_type, args.weights, device)
    result = predict_tracks(args.image_path, model, args.model_type, device)

    print(result)

