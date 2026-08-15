"""Manipulation ground-truth mask processor, alignment, and binarization."""

from pathlib import Path
from typing import Optional, Tuple
import cv2
import numpy as np
import torch


def load_and_align_mask(
    mask_path: Optional[str or Path],
    target_shape: Tuple[int, int] = (256, 256),
    is_manipulated: bool = True,
) -> np.ndarray:
    """
    Load a binary manipulation ground-truth mask or generate an all-zeros mask.
    
    Args:
        mask_path: Path to the binary mask image file (if exists).
        target_shape: Target (height, width) for model alignment.
        is_manipulated: If False, returns an all-zeros mask regardless of path.
        
    Returns:
        Binary numpy array of shape (height, width) with values in {0, 1} (uint8).
    """
    h, w = target_shape
    if not is_manipulated or mask_path is None or not Path(mask_path).exists():
        return np.zeros((h, w), dtype=np.uint8)

    # Read mask as grayscale
    raw_mask = cv2.imread(str(mask_path), cv2.IMREAD_GRAYSCALE)
    if raw_mask is None:
        return np.zeros((h, w), dtype=np.uint8)

    # Resize using nearest-neighbor interpolation to prevent boundary blur artifacts
    if raw_mask.shape != (h, w):
        aligned_mask = cv2.resize(raw_mask, (w, h), interpolation=cv2.INTER_NEAREST)
    else:
        aligned_mask = raw_mask

    # Strict binarization to {0, 1}
    binary_mask = (aligned_mask > 127).astype(np.uint8)
    return binary_mask


def mask_to_tensor(mask: np.ndarray) -> torch.Tensor:
    """Convert a 2D binary numpy mask to a PyTorch float tensor of shape (1, H, W)."""
    return torch.from_numpy(mask).unsqueeze(0).float()
