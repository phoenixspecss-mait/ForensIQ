# Deepfake Forensic Audit Report

**Report ID:** `DF-712FAEBA`  
**Generated:** `2026-08-15 16:24:37 UTC`  
**Target Media:** `output/synthetic_face.png` (`png`)  

---

## 1. Executive Summary

| Parameter | Value |
| :--- | :--- |
| **Verdict** | 🟡 **UNCERTAIN** |
| **Deepfake Score** | `0.3525` |
| **Confidence Level** | `74.1%` |

### **Recommendation**
> MODERATE RISK: Ambiguous anomaly indicators. Secondary manual review recommended.

---

## 2. Multi-Modal Analysis Breakdown

| Modality | Score | Confidence | Weight | Detected Anomalies |
| :--- | :--- | :--- | :--- | :--- |
| `SPATIAL` | `0.150` | `88%` | `0.35` | None |
| `FREQUENCY` | `0.900` | `85%` | `0.25` | Periodic high-frequency spectral grid artifacts detected |
| `TEMPORAL` | `0.200` | `50%` | `0.05` | None |
| `AUDIO` | `0.150` | `50%` | `0.05` | None |
| `METADATA` | `0.250` | `90%` | `0.05` | None |

### Audit Rationale
- FINAL VERDICT: UNCERTAIN. Aggregated score 0.353 falls in ambiguity window (0.35 - 0.60).
- Low anomaly in [SPATIAL] modality (score: 0.15): consistent with authentic media.
- High anomaly detected in [FREQUENCY] modality (score: 0.90, weight: 0.25): FFT 2D spectral decomposition identified high-frequency magnitude level of 165.44.
- Low anomaly in [TEMPORAL] modality (score: 0.20): consistent with authentic media.
- Low anomaly in [AUDIO] modality (score: 0.15): consistent with authentic media.
- Low anomaly in [METADATA] modality (score: 0.25): consistent with authentic media.

---

## 3. Visual Explainability (Grad-CAM)

- **Target Layer:** `conv_final`
- **Overlay Image:** `output/DF-712FAEBA_gradcam_overlay.png`
- **Summary:** Grad-CAM visual analysis detected 1 localized anomaly regions with peak intensity 1.00.

| Bounding Box (x, y, w, h) | Peak Activation | Intensity | Anomaly Label |
| :--- | :--- | :--- | :--- |
| `(115, 115, 283, 283)` | `1.000` | **Critical** | Critical facial blending boundary mismatch at (115, 115) |

---

## 4. Media Metadata Details

- **File Path:** `output/synthetic_face.png`
- **File Type:** `png`
- **Resolution:** `(1080, 1080)`
- **Duration (sec):** `N/A`
- **Frames Processed:** `N/A`
- **Checksum (SHA-256):** `3a59ed430f61a74f49b3e8200f27651a5581a53667263925022da98cf7cda617`
