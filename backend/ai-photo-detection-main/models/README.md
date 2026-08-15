# Model Artifacts & Checkpoints Storage

This directory stores trained model checkpoints, serialized weights, and exported models:
- `checkpoints/`: Epoch-by-epoch training checkpoints (`.pt` / `.pth`).
- `best_models/`: Optimal weights selected via validation Macro-F1.
- `exported/`: ONNX / TorchScript optimized models for application deployment.
