"""
Classical pixel-forensics feature extractors.
These run BEFORE the neural net and give you signals that don't need training.

Run this file directly to sanity-check the functions on a sample image:
    python forensics.py path/to/image.jpg
"""

import cv2
import numpy as np
from scipy import fftpack
from PIL import Image
import io


def error_level_analysis(image_path: str, quality: int = 90) -> np.ndarray:
    """
    ELA: resave the image at a known JPEG quality, then diff against the original.
    Manipulated/spliced regions often show a different error level than the
    untouched parts of the image, because they were compressed a different
    number of times or at different quality.

    Returns a single-channel (H, W) float32 array of amplified pixel differences.
    """
    original = Image.open(image_path).convert("RGB")

    buffer = io.BytesIO()
    original.save(buffer, "JPEG", quality=quality)
    buffer.seek(0)
    resaved = Image.open(buffer)

    orig_np = np.array(original).astype(np.int16)
    resaved_np = np.array(resaved).astype(np.int16)

    diff = np.abs(orig_np - resaved_np).astype(np.float32)
    diff_gray = diff.mean(axis=2)

    # amplify so differences are visible / usable as a signal
    max_val = diff_gray.max() if diff_gray.max() > 0 else 1.0
    diff_gray = (diff_gray / max_val) * 255.0

    return diff_gray.astype(np.float32)


def noise_residual(image_path: str, kernel_size: int = 3) -> np.ndarray:
    """
    Extracts the high-frequency noise residual: original - denoised(original).
    Real camera images carry a consistent sensor-noise fingerprint.
    GAN/diffusion images often produce unnaturally smooth or patterned residuals.

    Returns a single-channel (H, W) float32 array.
    """
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Could not read image: {image_path}")

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY).astype(np.float32)
    denoised = cv2.medianBlur(gray.astype(np.uint8), kernel_size).astype(np.float32)

    residual = gray - denoised
    return residual


def frequency_spectrum(image_path: str) -> np.ndarray:
    """
    2D FFT magnitude spectrum. GAN upsampling layers (transpose conv / pixel
    shuffle) often leave periodic grid-like artifacts visible as peaks in the
    frequency domain that real camera images don't have.

    Returns a single-channel (H, W) float32 log-magnitude spectrum.
    """
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE).astype(np.float32)

    f = fftpack.fft2(img)
    fshift = fftpack.fftshift(f)
    magnitude = np.abs(fshift)

    # log scale so it's visually/numerically usable
    log_magnitude = np.log1p(magnitude)
    return log_magnitude.astype(np.float32)


def get_all_forensic_features(image_path: str) -> dict:
    """Convenience wrapper returning all three signals at once."""
    return {
        "ela": error_level_analysis(image_path),
        "noise_residual": noise_residual(image_path),
        "frequency": frequency_spectrum(image_path),
    }


if __name__ == "__main__":
    import sys
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    if len(sys.argv) < 2:
        print("Usage: python forensics.py <image_path>")
        sys.exit(1)

    path = sys.argv[1]
    features = get_all_forensic_features(path)

    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    for ax, (name, arr) in zip(axes, features.items()):
        ax.imshow(arr, cmap="gray")
        ax.set_title(name)
        ax.axis("off")

    out_path = "forensics_preview.png"
    plt.savefig(out_path, bbox_inches="tight")
    print(f"Saved preview to {out_path}")
    for name, arr in features.items():
        print(f"{name}: shape={arr.shape}, min={arr.min():.2f}, max={arr.max():.2f}")
