"""
PyTorch Dataset that returns:
  - RGB image tensor
  - noise residual tensor (single channel)
  - label (0 = real, 1 = fake)

Expects folder layout:
    data/real/*.jpg
    data/fake/*.jpg

Run directly to sanity-check on one batch:
    python dataset.py
"""

import os
import glob
import random

import cv2
import numpy as np
import torch
from torch.utils.data import Dataset
from torchvision import transforms

from forensics import noise_residual


class ForensicDataset(Dataset):
    def __init__(self, root_dir="data", image_size=224, train=True):
        self.image_size = image_size
        self.train = train

        real_paths = glob.glob(os.path.join(root_dir, "real", "*"))
        fake_paths = glob.glob(os.path.join(root_dir, "fake", "*"))

        self.samples = [(p, 0) for p in real_paths] + [(p, 1) for p in fake_paths]
        random.shuffle(self.samples)

        if len(self.samples) == 0:
            raise RuntimeError(
                f"No images found in {root_dir}/real or {root_dir}/fake. "
                "Add some images before training."
            )

        # normalization matches standard ImageNet-pretrained backbones (timm default)
        self.rgb_transform = transforms.Compose([
            transforms.ToPILImage(),
            transforms.Resize((image_size, image_size)),
            transforms.RandomHorizontalFlip() if train else transforms.Lambda(lambda x: x),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])

    def __len__(self):
        return len(self.samples)

    def _maybe_jpeg_recompress(self, img_bgr):
        """Random JPEG recompression augmentation so the model doesn't
        overfit to one dataset's specific compression fingerprint."""
        if self.train and random.random() < 0.5:
            quality = random.randint(60, 95)
            success, encoded = cv2.imencode(".jpg", img_bgr, [cv2.IMWRITE_JPEG_QUALITY, quality])
            if success:
                img_bgr = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
        return img_bgr

    def __getitem__(self, idx):
        path, label = self.samples[idx]

        img_bgr = cv2.imread(path)
        if img_bgr is None:
            # fallback: skip corrupt file by grabbing another random sample
            return self.__getitem__(random.randint(0, len(self.samples) - 1))

        img_bgr = self._maybe_jpeg_recompress(img_bgr)
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

        rgb_tensor = self.rgb_transform(img_rgb)

        # noise residual computed on grayscale, resized to match
        residual = noise_residual(path)
        residual = cv2.resize(residual, (self.image_size, self.image_size))
        residual = (residual - residual.mean()) / (residual.std() + 1e-6)  # normalize
        residual_tensor = torch.from_numpy(residual).unsqueeze(0).float()  # (1, H, W)

        return rgb_tensor, residual_tensor, torch.tensor(label, dtype=torch.long)


if __name__ == "__main__":
    from torch.utils.data import DataLoader

    ds = ForensicDataset(root_dir="data", train=True)
    print(f"Dataset size: {len(ds)}")

    loader = DataLoader(ds, batch_size=4, shuffle=True)
    rgb, residual, labels = next(iter(loader))
    print(f"RGB batch shape: {rgb.shape}")
    print(f"Residual batch shape: {residual.shape}")
    print(f"Labels: {labels}")
