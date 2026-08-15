"""
main_pipeline.py
-----------------
Orchestrates the aggregation module end-to-end, in the sequence you'd
wire it up for the demo:

    sub-model scores  --->  score_fusion  --->  gradcam (on tampered
    regions)  --->  schemas validate everything  --->  report_generator
    renders the final PDF

This file is deliberately runnable stand-alone with dummy inputs so you
can demo the aggregation module BEFORE your teammates' image/video/audio
models are fully wired in. Swap `demo_run()` internals for real model
calls when ready.
"""

from __future__ import annotations
import hashlib
import os

from schemas import (
    ModalityScore, ForensicMetadata, AuditReport,
)
from score_fusion import weighted_soft_vote
from report_generator import build_audit_pdf
# from gradcam_module import generate_gradcam_overlay  # enable once a real model is wired in


def compute_file_hash(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def run_pipeline(
    input_file_path: str,
    modality_scores: list[ModalityScore],
    output_pdf_path: str,
    gradcam_overlays: list | None = None,
    notes: str | None = None,
) -> str:
    """
    Full sequence: fuse scores -> validate -> render PDF.
    Returns the path to the generated PDF.
    """
    # 1. Fusion
    fusion_result = weighted_soft_vote(modality_scores)

    # 2. Forensic metadata (real-world: pull actual EXIF via exiftool / Pillow)
    forensic_metadata = ForensicMetadata(
        file_name=os.path.basename(input_file_path),
        file_hash_sha256=(
            compute_file_hash(input_file_path)
            if os.path.exists(input_file_path) else "DEMO_FILE_NOT_FOUND"
        ),
        creation_software="Unknown",
        gps_present=False,
        exif_modified_flag=False,
        c2pa_signature_valid=None,
    )

    # 3. Schema-validated report object (raises if anything is malformed)
    report = AuditReport(
        report_id=f"RPT-{compute_file_hash(input_file_path)[:10]}"
        if os.path.exists(input_file_path) else "RPT-DEMO0001",
        input_file=input_file_path,
        forensic_metadata=forensic_metadata,
        fusion_result=fusion_result,
        gradcam_overlays=gradcam_overlays or [],
        notes=notes,
    )

    # 4. PDF rendering
    build_audit_pdf(report, output_pdf_path)
    return output_pdf_path


def demo_run():
    """Runs the whole aggregation module with dummy sub-model outputs
    so you can present it before real models are integrated."""
    demo_scores = [
        ModalityScore(modality="image", model_name="xception_deepfake_v3",
                      fake_probability=0.82, processing_time_ms=120.0),
        ModalityScore(modality="video_temporal", model_name="video_transformer_v1",
                      fake_probability=0.74, processing_time_ms=980.0),
        ModalityScore(modality="audio", model_name="wav2vec2_spoof_v2",
                      fake_probability=0.55, processing_time_ms=340.0),
    ]

    out_path = run_pipeline(
        input_file_path="sample_input.mp4",
        modality_scores=demo_scores,
        output_pdf_path="outputs/demo_audit_report.pdf",
        notes="Demo run using placeholder sub-model scores prior to full model integration.",
    )
    print(f"Report generated at: {out_path}")


if __name__ == "__main__":
    os.makedirs("outputs", exist_ok=True)
    demo_run()
