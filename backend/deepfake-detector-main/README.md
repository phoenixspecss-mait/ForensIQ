# Part 2: Image AI & Pixel Forensics — Run Order

## 1. Install dependencies
```bash
pip install -r requirements.txt --break-system-packages
```

## 2. Add your data
```
data/real/   <- put real photos here
data/fake/   <- put AI-generated / deepfake images here
```
Get datasets from FaceForensics++, CIFAKE, or generate your own fake set with
Midjourney/SDXL/DALL-E outputs.

## 3. Sanity-check the forensic feature extractors
```bash
python forensics.py data/real/some_image.jpg
```
Check `forensics_preview.png` — you want to visually see fakes differ from reals
in ELA / noise residual / frequency spectrum before trusting them as inputs.

## 4. Sanity-check the data loader
```bash
python dataset.py
```
Should print dataset size and batch shapes with no errors.

## 5. Sanity-check the model architecture
```bash
python model.py
```
Should print output shapes `(2, 2)` for both models (downloads pretrained
ImageNet weights on first run — needs internet).

## 6. Train the baseline first
```bash
python train.py --model baseline --epochs 10
```
Watch `val_auc` climb each epoch. This confirms your whole pipeline (data,
loss, backprop, eval) actually works before adding complexity.

## 7. Train the dual-stream model
```bash
python train.py --model dual --epochs 10
```
Compare its `val_auc` against the baseline's saved best. Only keep it if it's
actually better — otherwise ship the simpler baseline.

## 8. Run inference / get confidence scores
```bash
python predict.py path/to/image.jpg --model_type baseline --weights best_baseline_model.pt
```
Returns `{"label": "real"|"fake", "confidence": 0-1, "raw_probs": {...}}` —
this is the function Part 1 (FastAPI) calls and Part 4 (reports/Grad-CAM) consumes.

## Notes
- `TEMPERATURE` in `predict.py` is currently a placeholder (1.5). Properly
  calibrate it against a held-out validation set once you have real trained
  weights — search "temperature scaling calibration" for the standard method.
- For Part 4's Grad-CAM, hook into `model.backbone` (baseline) or
  `model.rgb_backbone` (dual-stream) — timm backbones expose their final conv
  layer cleanly for this.
- Always validate on a generator your model has NEVER seen during training
  (e.g. train on StyleGAN, test on Midjourney). This is the #1 way published
  deepfake detectors fail in the real world.
