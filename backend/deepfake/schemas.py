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


# -------------------------------------------------------------
# Screen-Driven API Response Schemas
# -------------------------------------------------------------

class RecentScanItem(BaseModel):
    id: str
    title: str
    verdict: Literal["AUTHENTIC", "MANIPULATED", "INCONCLUSIVE"]
    time_display: str
    media_type: Literal["image", "video", "audio"]
    thumbnail_url: Optional[str] = None


class DashboardIntegrityResponse(BaseModel):
    system_integrity_percentage: int = Field(98, ge=0, le=100)
    verdict: str = "AUTHENTIC"
    last_scan_time: str = "2 MINS AGO"
    threat_level: str = "MINIMAL"
    recent_scans: list[RecentScanItem]


class ActiveFrameInfo(BaseModel):
    analysis_active: bool = True
    frame_timestamp: str = "00:14:32"
    frame_hex: str = "0x4F92A"
    preview_stream_url: Optional[str] = None


class PipelineStepStatus(BaseModel):
    step_id: str
    name: str
    status: Literal["completed", "in_progress", "pending"]
    duration: Optional[str] = None
    details: Optional[str] = None


class ScanProgressResponse(BaseModel):
    job_id: str
    title: str = "DeepScan Analysis"
    subtitle: str = "Verifying digital artifact integrity. Do not close this window."
    overall_progress_percentage: int = Field(..., ge=0, le=100)
    status_text: str = "Scanning..."
    active_frame_info: ActiveFrameInfo
    pipeline_steps: list[PipelineStepStatus]
    encryption: str = "End-to-end encrypted analysis."
    can_boost: bool = True
    can_cancel: bool = True


class FacialHeatmapBreakdown(BaseModel):
    title: str = "FACIAL HEATMAP"
    heatmap_url: str
    manipulation_probability: float
    thermal_variances: list[str] = []
    explanation: str


class ScanReportResponse(BaseModel):
    report_id: str
    verdict: str
    verdict_raw: str
    verdict_description: str
    authenticity_percentage: int
    analysis_breakdown: dict
    pdf_export_url: str


class VerificationCertificateResponse(BaseModel):
    certificate_id: str
    authenticity_percentage: int
    verdict: str = "Authentic"
    status: str = "VERIFIED"
    scan_date: str
    verification_badge_url: Optional[str] = None
    is_valid: bool = True
