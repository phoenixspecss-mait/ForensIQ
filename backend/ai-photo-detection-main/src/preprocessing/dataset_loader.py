"""PyTorch Forensic Dataset and DataLoader implementation with non-destructive loading and online augmentations."""

import io
from pathlib import Path
from typing import Callable, Dict, Optional, Tuple, Union
import numpy as np
import pandas as pd
import torch
from torch.utils.data import DataLoader, Dataset
from PIL import Image

from src.preprocessing.format_standardizer import (
    center_crop_and_resize,
    load_raw_image_rgb,
    normalize_to_tensor,
)
from src.preprocessing.mask_processor import load_and_align_mask, mask_to_tensor


LABEL_MAPPING_MULTICLASS = {
    "real": 0,
    "ai_generated": 1,
    "manipulated": 2,
}

LABEL_MAPPING_TRACK_A = {
    "real": 0,
    "ai_generated": 1,
}

LABEL_MAPPING_TRACK_B = {
    "real": 0,
    "manipulated": 1,
}


def apply_online_jpeg_compression(img_array: np.ndarray, quality: int) -> np.ndarray:
    """Simulate in-memory JPEG recompression without touching disk files."""
    pil_img = Image.fromarray(img_array)
    buffer = io.BytesIO()
    pil_img.save(buffer, format="JPEG", quality=quality)
    buffer.seek(0)
    with Image.open(buffer) as recompressed_pil:
        recompressed_array = np.array(recompressed_pil.convert("RGB"), dtype=np.uint8)
    return recompressed_array


class ForensicDataset(Dataset):
    """
    Multitask Forensic Dataset supporting whole-image classification and pixel-level mask localization.
    """

    def __init__(
        self,
        manifest: Union[pd.DataFrame, str, Path],
        mode: str = "multiclass", # options: 'multiclass', 'track_a', 'track_b'
        target_size: Tuple[int, int] = (256, 256),
        is_training: bool = False,
        jpeg_aug_prob: float = 0.5,
        jpeg_quality_range: Tuple[int, int] = (65, 95),
        strip_border_px: int = 0,
    ):
        if isinstance(manifest, (str, Path)):
            self.manifest_df = pd.read_csv(manifest)
        else:
            self.manifest_df = manifest.copy().reset_index(drop=True)

        self.mode = mode
        self.target_size = target_size
        self.is_training = is_training
        self.jpeg_aug_prob = jpeg_aug_prob
        self.jpeg_quality_range = jpeg_quality_range
        self.strip_border_px = strip_border_px

        # Select label mapping based on mode
        if self.mode == "multiclass":
            self.label_map = LABEL_MAPPING_MULTICLASS
        elif self.mode == "track_a":
            self.label_map = LABEL_MAPPING_TRACK_A
        elif self.mode == "track_b":
            self.label_map = LABEL_MAPPING_TRACK_B
        else:
            raise ValueError(f"Unknown dataset mode: {self.mode}")

    def __len__(self) -> int:
        return len(self.manifest_df)

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor, Dict]:
        row = self.manifest_df.iloc[idx]
        file_path = row["file_path"]
        class_str = str(row["class"]).lower().strip()
        label_int = self.label_map.get(class_str, 0)

        # 1. Non-destructive raw RGB loading
        raw_rgb = load_raw_image_rgb(file_path)

        # 2. Online JPEG augmentation during training only
        if self.is_training and np.random.rand() < self.jpeg_aug_prob:
            q_val = int(np.random.randint(self.jpeg_quality_range[0], self.jpeg_quality_range[1] + 1))
            raw_rgb = apply_online_jpeg_compression(raw_rgb, quality=q_val)

        # 3. Central crop and resize
        standardized_rgb = center_crop_and_resize(
            raw_rgb,
            target_size=self.target_size,
            strip_border_px=self.strip_border_px,
        )

        # 4. Tensor Normalization
        image_tensor = normalize_to_tensor(standardized_rgb, apply_imagenet_norm=True)

        # 5. Mask Processing (Load ground truth if manipulated, otherwise all-zeros)
        mask_path = row.get("mask_path", None)
        is_manip = class_str == "manipulated"
        mask_np = load_and_align_mask(
            mask_path=mask_path if pd.notna(mask_path) else None,
            target_shape=self.target_size,
            is_manipulated=is_manip,
        )
        mask_tensor_out = mask_to_tensor(mask_np)

        # 6. Metadata dictionary
        metadata = {
            "file_path": str(file_path),
            "class": class_str,
            "generator": str(row.get("generator", "none")),
            "manipulation_type": str(row.get("manipulation_type", "none")),
            "source_id": str(row.get("source_id", "none")),
        }

        return image_tensor, mask_tensor_out, torch.tensor(label_int, dtype=torch.long), metadata


def create_dataloader(
    manifest: Union[pd.DataFrame, str, Path],
    batch_size: int = 16,
    is_training: bool = False,
    mode: str = "multiclass",
    target_size: Tuple[int, int] = (256, 256),
    num_workers: int = 0,
    shuffle: Optional[bool] = None,
) -> DataLoader:
    """Create a configured PyTorch DataLoader."""
    dataset = ForensicDataset(
        manifest=manifest,
        mode=mode,
        target_size=target_size,
        is_training=is_training,
    )
    if shuffle is None:
        shuffle = is_training

    return DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=shuffle,
        num_workers=num_workers,
        pin_memory=False,
    )
