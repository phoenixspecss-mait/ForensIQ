"""
report_generator.py
--------------------
Renders a validated AuditReport (schemas.py) into an audit-ready PDF:
metadata trace table, per-modality confidence scores, fusion verdict,
and embedded Grad-CAM overlay images.

Install: pip install reportlab
"""

from __future__ import annotations
import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak,
)

from schemas import AuditReport

VERDICT_COLORS = {
    "AUTHENTIC": colors.HexColor("#1e8e3e"),
    "LIKELY_MANIPULATED": colors.HexColor("#f9a825"),
    "MANIPULATED": colors.HexColor("#d32f2f"),
}


def _styles():
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(
        name="ReportTitle", fontSize=20, leading=24, spaceAfter=6,
        textColor=colors.HexColor("#1a1a2e"),
    ))
    styles.add(ParagraphStyle(
        name="SectionHeader", fontSize=13, leading=16, spaceBefore=14,
        spaceAfter=6, textColor=colors.HexColor("#16213e"),
    ))
    return styles


def build_audit_pdf(report: AuditReport, output_path: str) -> str:
    styles = _styles()
    doc = SimpleDocTemplate(
        output_path, pagesize=A4,
        topMargin=2 * cm, bottomMargin=2 * cm,
        leftMargin=2 * cm, rightMargin=2 * cm,
    )
    story = []

    # --- Header ---
    story.append(Paragraph("Digital Media Authenticity — Forensic Report", styles["ReportTitle"]))
    story.append(Paragraph(f"Report ID: {report.report_id}", styles["Normal"]))
    story.append(Paragraph(f"Generated: {report.generated_at.isoformat()}", styles["Normal"]))
    story.append(Paragraph(f"Input file: {report.input_file}", styles["Normal"]))
    story.append(Spacer(1, 0.5 * cm))

    # --- Verdict banner ---
    fr = report.fusion_result
    verdict_color = VERDICT_COLORS.get(fr.verdict, colors.grey)
    verdict_table = Table(
        [[f"VERDICT: {fr.verdict}",
          f"Fake probability: {fr.final_fake_probability:.1%}",
          f"Confidence: {fr.confidence:.1%}"]],
        colWidths=[6 * cm, 6 * cm, 5 * cm],
    )
    verdict_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, 0), verdict_color),
        ("TEXTCOLOR", (0, 0), (0, 0), colors.white),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("FONTNAME", (0, 0), (0, 0), "Helvetica-Bold"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
        ("INNERGRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    story.append(verdict_table)
    story.append(Spacer(1, 0.7 * cm))

    # --- Forensic metadata table ---
    story.append(Paragraph("Forensic Metadata", styles["SectionHeader"]))
    fm = report.forensic_metadata
    meta_rows = [
        ["File name", fm.file_name],
        ["SHA-256", fm.file_hash_sha256],
        ["Creation software", fm.creation_software or "Unknown"],
        ["GPS data present", "Yes" if fm.gps_present else "No"],
        ["EXIF modified flag", "Yes" if fm.exif_modified_flag else "No"],
        ["C2PA signature valid", str(fm.c2pa_signature_valid)],
    ]
    meta_table = Table(meta_rows, colWidths=[5 * cm, 12 * cm])
    meta_table.setStyle(TableStyle([
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#f0f0f5")),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#cccccc")),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 0.7 * cm))

    # --- Per-modality scores ---
    story.append(Paragraph("Sub-Model Scores", styles["SectionHeader"]))
    score_rows = [["Modality", "Model", "Fake probability", "Latency (ms)"]]
    for s in fr.contributing_scores:
        score_rows.append([
            s.modality, s.model_name, f"{s.fake_probability:.1%}",
            f"{s.processing_time_ms:.0f}",
        ])
    score_table = Table(score_rows, colWidths=[4 * cm, 6 * cm, 4 * cm, 3 * cm])
    score_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#16213e")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#cccccc")),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.append(score_table)
    story.append(Spacer(1, 0.5 * cm))
    story.append(Paragraph(f"Fusion method: {fr.fusion_method}", styles["Normal"]))

    # --- Grad-CAM overlays ---
    if report.gradcam_overlays:
        story.append(PageBreak())
        story.append(Paragraph("Visual Explainability (Grad-CAM)", styles["SectionHeader"]))
        for overlay in report.gradcam_overlays:
            if os.path.exists(overlay.overlay_path):
                label = f"{overlay.modality}" + (
                    f" — frame {overlay.frame_index}" if overlay.frame_index is not None else ""
                )
                story.append(Paragraph(label, styles["Normal"]))
                story.append(Image(overlay.overlay_path, width=10 * cm, height=10 * cm))
                story.append(Spacer(1, 0.4 * cm))

    if report.notes:
        story.append(Spacer(1, 0.5 * cm))
        story.append(Paragraph("Notes", styles["SectionHeader"]))
        story.append(Paragraph(report.notes, styles["Normal"]))

    doc.build(story)
    return output_path
