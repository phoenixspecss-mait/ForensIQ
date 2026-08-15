"""Deduplication and near-duplicate filtering using cryptographic and perceptual hashing."""

import hashlib
from pathlib import Path
from typing import Dict, List, Set, Tuple
from PIL import Image
import imagehash
import pandas as pd


def compute_md5(file_path: Path) -> str:
    """Compute MD5 checksum for exact duplicate detection."""
    hasher = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def compute_phash(file_path: Path, hash_size: int = 8) -> str:
    """Compute 64-bit Perceptual Hash (pHash) for near-duplicate detection."""
    with Image.open(file_path) as img:
        # Convert to grayscale for consistent perceptual hashing
        gray_img = img.convert("L")
        phash_val = imagehash.phash(gray_img, hash_size=hash_size)
    return str(phash_val)


def filter_duplicates(
    manifest_df: pd.DataFrame,
    phash_hamming_threshold: int = 5,
    file_path_col: str = "file_path",
) -> Tuple[pd.DataFrame, Set[str]]:
    """
    Filter exact duplicates and near-duplicates based on MD5 and pHash Hamming distance.
    
    Args:
        manifest_df: DataFrame containing image file paths.
        phash_hamming_threshold: Maximum Hamming distance to consider two images duplicates.
        file_path_col: Name of column containing absolute or relative file paths.
        
    Returns:
        Tuple of (deduplicated_dataframe, set_of_dropped_file_paths).
    """
    dropped_files: Set[str] = set()
    seen_md5: Set[str] = set()
    seen_phashes: List[Tuple[imagehash.ImageHash, str]] = []
    keep_indices: List[int] = []

    for idx, row in manifest_df.iterrows():
        path_val = Path(row[file_path_col])
        if not path_val.exists():
            dropped_files.add(str(path_val))
            continue

        # 1. Exact MD5 check
        md5_val = compute_md5(path_val)
        if md5_val in seen_md5:
            dropped_files.add(str(path_val))
            continue
        seen_md5.add(md5_val)

        # 2. Perceptual Hash near-duplicate check
        try:
            curr_phash = imagehash.hex_to_hash(compute_phash(path_val))
        except Exception:
            dropped_files.add(str(path_val))
            continue

        is_near_dup = False
        for prev_hash, _ in seen_phashes:
            if curr_phash - prev_hash <= phash_hamming_threshold:
                is_near_dup = True
                dropped_files.add(str(path_val))
                break

        if not is_near_dup:
            seen_phashes.append((curr_phash, str(path_val)))
            keep_indices.append(idx)

    dedup_df = manifest_df.loc[keep_indices].copy().reset_index(drop=True)
    return dedup_df, dropped_files
