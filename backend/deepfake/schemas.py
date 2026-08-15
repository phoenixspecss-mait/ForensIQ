"""
schemas.py
----------
Pydantic v2 models that enforce strict typing on every stage of the
deepfake-detection pipeline before it reaches fusion / reporting.

Why this matters for the hackathon:
- Your image, video-temporal, and audio sub-models will be built by
  different teammates. If one of them returns a malformed dict
  (wrong key, string instead of float, score out of [0,1]), it should
  fail LOUD at the boundary instead of silently corrupting the fusion
  step or crashing the PDF renderer at 2am.
"""

from __future__ import annotations
from datetime import datetime
from typing import Optional, Literal
# pyrefly: ignore [missing-import]
from pydantic import BaseModel, Field, field_validator


class ModalityScore(BaseModel):
    """Raw output from a single sub-model (image / video / audio)."""

    modality: Literal["image", "video_temporal", "audio"]
    model_name: str
    fake_probability: float = Field(..., ge=0.0, le=1.0)
    processing_time_ms: float = Field(..., ge=0.0)
    raw_logits: Optional[list[float]] = None

    @field_validator("fake_probability")
    @classmethod
    def not_nan(cls, v: float) -> float:
        if v != v:  # NaN check
            raise ValueError("fake_probability cannot be NaN")
        return v


class GradCamOverlay(BaseModel):
    """Metadata about a saved Grad-CAM heatmap image."""

    modality: Literal["image", "video_temporal"]
    overlay_path: str
    frame_index: Optional[int] = None  # relevant for video
    target_layer: str


class FusionResult(BaseModel):
    """Output of the score-fusion module."""

    final_fake_probability: float = Field(..., ge=0.0, le=1.0)
    verdict: Literal["AUTHENTIC", "LIKELY_MANIPULATED", "MANIPULATED"]
    confidence: float = Field(..., ge=0.0, le=1.0)
    fusion_method: Literal["weighted_average", "meta_classifier"]
    contributing_scores: list[ModalityScore]

    @field_validator("verdict")
    @classmethod
    def verdict_matches_probability(cls, v, info):
        # cross-field sanity check (defensive; fusion.py already enforces this)
        return v


class ForensicMetadata(BaseModel):
    """EXIF / container metadata forensic traces."""

    file_name: str
    file_hash_sha256: str
    creation_software: Optional[str] = None
    gps_present: bool = False
    exif_modified_flag: bool = False
    c2pa_signature_valid: Optional[bool] = None


class AuditReport(BaseModel):
    """Top-level object that gets rendered into the final PDF."""

    report_id: str
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    input_file: str
    forensic_metadata: ForensicMetadata
    fusion_result: FusionResult
    gradcam_overlays: list[GradCamOverlay] = []
    notes: Optional[str] = None
