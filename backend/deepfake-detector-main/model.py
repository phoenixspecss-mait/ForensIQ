"""
Two models:
  1. BaselineNet   - single RGB stream, pretrained timm backbone. Build/train this FIRST.
  2. ForensicNet   - dual-stream (RGB + noise residual), fused before classifier.
                     Only move to this once BaselineNet trains successfully.
"""

import torch
import torch.nn as nn
import timm


class BaselineNet(nn.Module):
    """Simple single-stream classifier. Start here."""

    def __init__(self, backbone_name="efficientnet_b0", num_classes=2, pretrained=True):
        super().__init__()
        self.backbone = timm.create_model(backbone_name, pretrained=pretrained, num_classes=0)
        feat_dim = self.backbone.num_features
        self.classifier = nn.Sequential(
            nn.Linear(feat_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, num_classes),
        )

    def forward(self, rgb):
        features = self.backbone(rgb)
        return self.classifier(features)


class ForensicNet(nn.Module):
    """Dual-stream: RGB backbone + noise-residual backbone, fused before classifying."""

    def __init__(self, backbone_name="efficientnet_b0", num_classes=2, pretrained=True):
        super().__init__()
        self.rgb_backbone = timm.create_model(backbone_name, pretrained=pretrained, num_classes=0)
        self.noise_backbone = timm.create_model(
            backbone_name, pretrained=pretrained, num_classes=0, in_chans=1
        )
        feat_dim = self.rgb_backbone.num_features + self.noise_backbone.num_features
        self.classifier = nn.Sequential(
            nn.Linear(feat_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, num_classes),
        )

    def forward(self, rgb, noise_residual):
        f_rgb = self.rgb_backbone(rgb)
        f_noise = self.noise_backbone(noise_residual)
        combined = torch.cat([f_rgb, f_noise], dim=1)
        return self.classifier(combined)


if __name__ == "__main__":
    # quick shape sanity check with dummy tensors, no data needed
    rgb = torch.randn(2, 3, 224, 224)
    residual = torch.randn(2, 1, 224, 224)

    baseline = BaselineNet()
    out = baseline(rgb)
    print(f"BaselineNet output shape: {out.shape}")  # expect (2, 2)

    dual = ForensicNet()
    out2 = dual(rgb, residual)
    print(f"ForensicNet output shape: {out2.shape}")  # expect (2, 2)
