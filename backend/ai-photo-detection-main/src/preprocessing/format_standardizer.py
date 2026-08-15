"""Non-destructive in-memory image loader, central cropping, and tensor normalization."""

from pathlib import Path
from typing import Tuple, Union
import cv2
import numpy as np
import torch
from PIL import Image


IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def load_raw_image_rgb(file_path: Union[str, Path]) -> np.ndarray:
    """
    Load raw image in memory without modifying source file on disk.
    Converts directly to RGB uint8 array [0, 255] and strips container headers in-memory.
    """
    path_obj = Path(file_path)
    if not path_obj.exists():
        raise FileNotFoundError(f"Image not found at {path_obj}")

    # Use PIL to read raw bytes safely across PNG, JPEG, TIFF, BMP, WebP
    with Image.open(path_obj) as img:
        rgb_img = img.convert("RGB")
        img_array = np.array(rgb_img, dtype=np.uint8)

    return img_array


def center_crop_and_resize(
    img_array: np.ndarray,
    target_size: Tuple[int, int] = (256, 256),
    strip_border_px: int = 0,
) -> np.ndarray:
    """
    Apply central square crop and antialiased bicubic resize to target resolution.
    
    Args:
        img_array: RGB uint8 array (H, W, 3).
        target_size: Target (height, width).
        strip_border_px: Optional outer border strip to remove watermark margins.
        
    Returns:
        Resized RGB uint8 array of shape (target_size[0], target_size[1], 3).
    """
    h, w, _ = img_array.shape
    
    # Optionally strip outer canvas margin
    if strip_border_px > 0 and h > 2 * strip_border_px and w > 2 * strip_border_px:
        img_array = img_array[strip_border_px : h - strip_border_px, strip_border_px : w - strip_border_px]
        h, w, _ = img_array.shape

    # Square central crop
    min_dim = min(h, w)
    start_y = (h - min_dim) // 2
    start_x = (w - min_dim) // 2
    cropped = img_array[start_y : start_y + min_dim, start_x : start_x + min_dim]

    # Antialiased bicubic resize
    target_h, target_w = target_size
    if cropped.shape[:2] != (target_h, target_w):
        resized = cv2.resize(cropped, (target_w, target_h), interpolation=cv2.INTER_CUBIC)
    else:
        resized = cropped

    return resized


def normalize_to_tensor(
    img_array: np.ndarray,
    apply_imagenet_norm: bool = True,
) -> torch.Tensor:
    """
    Convert RGB uint8 array [0, 255] (H, W, 3) to PyTorch FloatTensor (3, H, W).
    """
    float_img = img_array.astype(np.float32) / 255.0

    if apply_imagenet_norm:
        float_img = (float_img - IMAGENET_MEAN) / IMAGENET_STD

    # (H, W, C) -> (C, H, W)
    tensor = torch.from_numpy(float_img).permute(2, 0, 1).contiguous().float()
    return tensor
