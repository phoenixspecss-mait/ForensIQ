# 🕵️ Deepfake & Digital Media Authenticity Verification

An AI-powered forensic platform that detects manipulated and AI-generated multimedia — images, video, and audio — by combining deep learning classifiers with classical digital forensics. The system outputs a confidence score and a visual, explainable audit report so users can verify whether content is real or synthetic before (or after) it's shared online.

> **Built for:** Brainwave 2026 — Problem Statement Set 1: *Deepfake & Digital Media Authenticity Verification*

---

## 📌 Problem Statement

The rapid advancement of generative AI has made it increasingly difficult to distinguish authentic digital media from manipulated content. Deepfake videos, AI-generated voices, and synthetic images pose significant risks to journalism, public safety, elections, businesses, and digital trust.

This project develops a solution capable of detecting manipulated or AI-generated multimedia by leveraging AI/ML models, digital forensics, metadata analysis, and content verification techniques — verifying images and videos, producing a confidence score, and helping users check authenticity before or after sharing content online.

---

## 🧩 System Architecture

The pipeline is organized into four modules, each targeting a different forensic signal, fused together into a single verdict:

```
                ┌─────────────────────────┐
                │   Input Media (Image /   │
                │   Video / Audio)         │
                └────────────┬─────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────────┐   ┌───────────────────┐
│ Part 2:        │   │ Part 3:            │   │ Metadata &         │
│ Image AI &      │   │ Video Biometrics &  │   │ Container-level     │
│ Pixel Forensics │   │ Audio AI            │   │ Analysis            │
└───────┬────────┘   └─────────┬──────────┘   └─────────┬──────────┘
        │                       │                          │
        └───────────────────────┼──────────────────────────┘
                                 ▼
                    ┌─────────────────────────┐
                    │ Part 4: Ensemble,         │
                    │ Grad-CAM & Reports        │
                    └────────────┬──────────────┘
                                 ▼
                    ┌─────────────────────────┐
                    │ Confidence Score +        │
                    │ Explainable Heatmaps +    │
                    │ PDF Audit Report          │
                    └─────────────────────────┘
```

---

## 🔍 Module Breakdown

### Part 2 — Image AI & Pixel Forensics

Detects synthetic media generation (GANs, Diffusion) and localized image tampering (splicing, inpainting, copy-move).

| Technique | Purpose |
|---|---|
| **Error Level Analysis (ELA)** | Identifies compression-level variations by re-saving the image at a fixed JPEG quality and computing the absolute pixel difference against the original |
| **Frequency Domain Analysis (2D-FFT / DCT)** | Exposes periodic grid artifacts and high-frequency discrepancies left behind by generative upsampling / transposed convolutions |
| **Noise Inconsistency & PRNU** | Analyzes sensor pattern noise residuals via high-pass/wavelet filtering to detect foreign pixel insertions |
| **Feature Extraction & Classification** | Pretrained vision backbones (EfficientNet, ConvNeXt, Swin Transformers) fine-tuned on real-vs-synthetic image datasets |

**References:** [PyTorch Docs](https://pytorch.org/docs/) · [`timm`](https://huggingface.co/docs/timm/) · [OpenCV Image Processing](https://docs.opencv.org/4.x/d2/d96/tutorial_py_table_of_contents_imgproc.html) · [SciPy Signal](https://docs.scipy.org/doc/scipy/reference/signal.html) · Krawetz, *"A Picture's Worth... Digital Image Analysis & Forensics"* (Black Hat, 2007) · Frank et al., *"Leveraging Frequency Analysis for Deep Fake Image Recognition"* (ICML, 2020)

---

### Part 3 — Video Biometrics & Audio AI

Extracts multimodal temporal signals from video streams and audio tracks to detect deepfake anomalies, voice cloning, and audio-visual sync flaws.

| Technique | Purpose |
|---|---|
| **Facial Landmark & Mesh Tracking** | Extracts 3D facial geometry across frames to compute Eye Aspect Ratio (blink patterns), head-pose consistency, and boundary-blending jitter |
| **Lip-Sync & Phoneme-Viseme Alignment** | Compares audio phonemes against visual visemes (mouth movements) via cross-modal embeddings to spot dubbed/replaced speech |
| **Spectral Audio Forensics** | Converts raw audio into Mel-Spectrograms, Constant-Q Transforms (CQT), and LFCCs to identify vocoder/TTS synthesis artifacts |
| **Temporal Frame Extraction** | Decodes synchronized keyframes and audio tracks from multimedia containers without heavy decoding overhead |

**References:** [MediaPipe Face Mesh](https://ai.google.dev/edge/mediapipe/solutions/vision/face_landmarker) · [`ffmpeg-python`](https://github.com/kkroening/ffmpeg-python) · [`librosa`](https://librosa.org/doc/latest/) · [`torchaudio`](https://pytorch.org/audio/stable/) · Agarwal et al., *"Protecting World Leaders Against Deep Fakes Using Facial, Gesture, and Vocal Mannerisms"* (CVPR, 2019) · [ASVspoof Challenge Series](https://www.asvspoof.org/)

---

### Part 4 — Ensemble, Grad-CAM & Reports

Aggregates multimodal sub-scores, provides visual explainability, and compiles forensic audit reports.

| Technique | Purpose |
|---|---|
| **Score Fusion / Late Ensembling** | Combines image, video-temporal, and audio model probabilities via weighted soft-voting, calibration, or a shallow meta-classifier (Logistic Regression / XGBoost) |
| **Grad-CAM / Grad-CAM++** | Computes gradients of the target class w.r.t. final convolutional feature maps to produce heatmaps highlighting tampered regions |
| **Schema Validation & Structured Data** | Enforces strict data types and JSON schemas for all pipeline outputs before reporting |
| **Automated PDF Generation** | Renders audit-ready forensic summaries with metadata traces, confidence scores, and Grad-CAM overlays |

**References:** [`pytorch-grad-cam`](https://github.com/jacobgil/pytorch-grad-cam) · [scikit-learn Ensemble & Calibration](https://scikit-learn.org/stable/modules/ensemble.html) · [Pydantic v2](https://docs.pydantic.dev/) · [ReportLab](https://docs.reportlab.com/) · Selvaraju et al., *"Grad-CAM: Visual Explanations from Deep Networks via Gradient-Based Localization"* (ICCV, 2017)

---

## 🛠️ Tech Stack

- **Deep Learning:** PyTorch, `timm` (EfficientNet, ConvNeXt, Swin Transformer backbones)
- **Computer Vision / Signal Processing:** OpenCV, SciPy
- **Video/Audio Processing:** MediaPipe (Face Mesh), `ffmpeg-python`, `librosa`, `torchaudio`
- **Explainability:** `pytorch-grad-cam`
- **Ensembling:** scikit-learn (soft-voting, calibration, XGBoost/Logistic Regression meta-classifier)
- **Data Validation:** Pydantic v2
- **Reporting:** ReportLab (PDF generation)

---

## 🚀 Getting Started

### Prerequisites
- Python 3.9+
- `ffmpeg` installed on system PATH (required by `ffmpeg-python`)

### Installation
```bash
git clone https://github.com/<your-org>/deepfake-authenticity-verification.git
cd deepfake-authenticity-verification
pip install -r requirements.txt
```

### Usage
```bash
python run_pipeline.py --input path/to/media_file
```

*(Update with your actual CLI/API entry point and arguments.)*

---

## 📊 Output

For every submitted image, video, or audio file, the pipeline produces:

- ✅ **Real / AI-generated verdict** with an overall confidence score
- 🔥 **Grad-CAM heatmap overlays** highlighting suspected tampered regions
- 📄 **PDF forensic audit report** containing metadata traces, per-module sub-scores, and visual evidence
- 🧾 **Structured JSON output** (schema-validated) for programmatic integration

---

## 📁 Project Structure

```
deepfake-authenticity-verification/
├── image_forensics/         # Part 2: ELA, FFT/DCT, PRNU, classifier backbones
├── video_audio_biometrics/  # Part 3: facial landmarks, lip-sync, spectral audio forensics
├── ensemble_reporting/      # Part 4: score fusion, Grad-CAM, PDF report generation
├── schemas/                 # Pydantic models / JSON schemas
├── data/                    # Sample/training data
├── models/                  # Trained model weights
├── requirements.txt
└── README.md
```

*(Update to match your actual repo layout.)*

---

## 🎯 Impact

- Gives journalists, platforms, and everyday users a fast way to check content authenticity before sharing
- Combines multiple independent forensic signals (pixel-level, frequency-domain, biometric, audio) rather than relying on a single detector, improving robustness against unseen generation methods
- Explainable outputs (Grad-CAM heatmaps + audit PDFs) make results interpretable and defensible, not just a black-box score

---

## 🔮 Future Scope

- Expand classifier training to keep pace with new generative architectures (newer diffusion/GAN variants)
- Add browser extension / social-media integration for pre-share verification
- Real-time video stream analysis for live broadcast verification
- Expand PRNU/sensor-noise database for camera-source attribution

---

## 👥 Team

*(Add team member names and roles here)*

## 📄 License

*(Add your chosen license, e.g., MIT)*
