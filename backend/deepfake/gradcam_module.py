"""
gradcam_module.py
------------------
Visual explainability layer. Wraps pytorch-grad-cam to highlight WHICH
pixels/regions drove the "fake" prediction for an image, or a sampled
frame from a video.

Install: pip install grad-cam torch torchvision opencv-python

Usage pattern:
    from gradcam_module import generate_gradcam_overlay
    overlay_meta = generate_gradcam_overlay(
        model=my_trained_cnn,
        target_layer=my_trained_cnn.layer4[-1],
        image_path="frame_012.jpg",
        output_dir="outputs/gradcam",
    )
"""

from __future__ import annotations
import os
import uuid
# pyrefly: ignore [missing-import]
import numpy as np
# pyrefly: ignore [missing-import]
import cv2
# pyrefly: ignore [missing-import]
import torch

# pyrefly: ignore [missing-import]
from pytorch_grad_cam import GradCAM, GradCAMPlusPlus
# pyrefly: ignore [missing-import]
from pytorch_grad_cam.utils.image import show_cam_on_image
# pyrefly: ignore [missing-import]
from pytorch_grad_cam.utils.model_targets import ClassifierOutputTarget

from schemas import GradCamOverlay


def _preprocess(image_path: str, input_size: int = 224):
    """Loads an image, returns (float32 RGB [0,1] for visualization,
    normalized tensor batch for the model)."""
    bgr = cv2.imread(image_path)
    if bgr is None:
        raise FileNotFoundError(f"Could not read image: {image_path}")

    bgr = cv2.resize(bgr, (input_size, input_size))
    rgb_float = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0

    mean = np.array([0.485, 0.456, 0.406])
    std = np.array([0.229, 0.224, 0.225])
    normalized = (rgb_float - mean) / std
    tensor = torch.from_numpy(normalized.transpose(2, 0, 1)).unsqueeze(0).float()
    return rgb_float, tensor


def generate_gradcam_overlay(
    model: torch.nn.Module,
    target_layer,
    image_path: str,
    output_dir: str,
    fake_class_index: int = 1,
    use_plus_plus: bool = True,
    frame_index: int | None = None,
) -> GradCamOverlay:
    """
    Runs Grad-CAM (or Grad-CAM++) on `image_path` against `target_layer`,
    saves a heatmap-overlay PNG, and returns validated metadata for it.

    - fake_class_index: the output-neuron index corresponding to "fake"
      in your classifier's final layer.
    - use_plus_plus: Grad-CAM++ generally localizes multiple/scattered
      tampered regions better than vanilla Grad-CAM; keep True unless
      you have a reason to compare against the original method.
    """
    os.makedirs(output_dir, exist_ok=True)
    model.eval()

    rgb_float, input_tensor = _preprocess(image_path)

    cam_algorithm = GradCAMPlusPlus if use_plus_plus else GradCAM
    with cam_algorithm(model=model, target_layers=[target_layer]) as cam:
        targets = [ClassifierOutputTarget(fake_class_index)]
        grayscale_cam = cam(input_tensor=input_tensor, targets=targets)[0, :]
        visualization = show_cam_on_image(rgb_float, grayscale_cam, use_rgb=True)

    out_name = f"gradcam_{uuid.uuid4().hex[:8]}.png"
    out_path = os.path.join(output_dir, out_name)
    cv2.imwrite(out_path, cv2.cvtColor(visualization, cv2.COLOR_RGB2BGR))

    return GradCamOverlay(
        modality="video_temporal" if frame_index is not None else "image",
        overlay_path=out_path,
        frame_index=frame_index,
        target_layer=target_layer.__class__.__name__,
    )


def generate_gradcam_for_video_frames(
    model: torch.nn.Module,
    target_layer,
    frame_paths: list[str],
    output_dir: str,
    fake_class_index: int = 1,
    max_frames: int = 5,
) -> list[GradCamOverlay]:
    """Runs Grad-CAM++ on a sampled subset of extracted video frames
    (don't run it on every frame of a video — pick evenly spaced samples,
    e.g. via ffmpeg, before calling this)."""
    overlays = []
    step = max(1, len(frame_paths) // max_frames)
    for idx in range(0, len(frame_paths), step)[:max_frames]:
        overlay = generate_gradcam_overlay(
            model=model,
            target_layer=target_layer,
            image_path=frame_paths[idx],
            output_dir=output_dir,
            fake_class_index=fake_class_index,
            frame_index=idx,
        )
        overlays.append(overlay)
    return overlays
