"""
score_fusion.py
----------------
Combines per-modality fake-probabilities (image / video-temporal / audio)
into one final score.

Two fusion strategies are implemented:

1. weighted_soft_vote()  -> simple, explainable, no training data needed.
   Good default for a hackathon demo since it works from minute 1.

2. MetaClassifierFusion  -> a shallow Logistic Regression / XGBoost model
   that learns the best combination weights from a small labeled
   validation set (real vs fake examples run through all sub-models).
   Use this once you have >~100 labeled samples to fit on.
"""

from __future__ import annotations
from typing import Sequence
# pyrefly: ignore [missing-import]
import numpy as np

from schemas import ModalityScore, FusionResult

try:
    from sklearn.linear_model import LogisticRegression
    from sklearn.calibration import CalibratedClassifierCV
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False


DEFAULT_WEIGHTS = {
    "image": 0.35,
    "video_temporal": 0.40,
    "audio": 0.25,
}

VERDICT_THRESHOLDS = (0.35, 0.65)  # < low -> AUTHENTIC, > high -> MANIPULATED


def _verdict_from_probability(p: float) -> str:
    low, high = VERDICT_THRESHOLDS
    if p < low:
        return "AUTHENTIC"
    if p > high:
        return "MANIPULATED"
    return "LIKELY_MANIPULATED"


def weighted_soft_vote(
    scores: Sequence[ModalityScore],
    weights: dict[str, float] | None = None,
) -> FusionResult:
    """
    Weighted average of sub-model probabilities. Missing modalities
    (e.g. an image-only submission has no audio score) are handled by
    renormalizing weights over whatever modalities are present.
    """
    weights = weights or DEFAULT_WEIGHTS
    present = {s.modality: s.fake_probability for s in scores}

    active_weights = {m: w for m, w in weights.items() if m in present}
    total_w = sum(active_weights.values())
    if total_w == 0:
        raise ValueError("No overlapping modalities between scores and weights")

    fused = sum(present[m] * (w / total_w) for m, w in active_weights.items())

    # confidence = how far the fused score sits from the uncertain middle band,
    # scaled by agreement (low variance across modalities => higher confidence)
    variance_penalty = float(np.var(list(present.values()))) if len(present) > 1 else 0.0
    distance_from_center = abs(fused - 0.5) * 2  # 0 (uncertain) -> 1 (decisive)
    confidence = max(0.0, min(1.0, distance_from_center - variance_penalty))

    return FusionResult(
        final_fake_probability=round(fused, 4),
        verdict=_verdict_from_probability(fused),
        confidence=round(confidence, 4),
        fusion_method="weighted_average",
        contributing_scores=list(scores),
    )


class MetaClassifierFusion:
    """
    Shallow meta-classifier fusion, trained on rows of
    [image_score, video_score, audio_score] -> label (0=real, 1=fake).

    Wraps the classifier in Platt-scaling calibration so the raw
    decision-function output is a well-calibrated probability, not
    just a rank score.
    """

    def __init__(self, kind: str = "logreg"):
        if not SKLEARN_AVAILABLE:
            raise ImportError("pip install scikit-learn to use MetaClassifierFusion")
        self.kind = kind
        self.feature_order = ["image", "video_temporal", "audio"]

        if kind == "logreg":
            base = LogisticRegression(max_iter=1000)
        elif kind == "xgboost":
            # pyrefly: ignore [missing-import]
            from xgboost import XGBClassifier  # optional dependency
            base = XGBClassifier(
                n_estimators=150, max_depth=3, learning_rate=0.08,
                use_label_encoder=False, eval_metric="logloss",
            )
        else:
            raise ValueError("kind must be 'logreg' or 'xgboost'")

        self.model = CalibratedClassifierCV(base, method="sigmoid", cv=3)
        self._fitted = False

    def _to_feature_row(self, scores: Sequence[ModalityScore]) -> np.ndarray:
        present = {s.modality: s.fake_probability for s in scores}
        # 0.5 (uncertain) as a neutral fill-in for a missing modality
        return np.array([[present.get(m, 0.5) for m in self.feature_order]])

    def fit(self, X: np.ndarray, y: np.ndarray) -> None:
        """X: shape (n_samples, 3) columns = [image, video, audio]. y: 0/1 labels."""
        self.model.fit(X, y)
        self._fitted = True

    def predict(self, scores: Sequence[ModalityScore]) -> FusionResult:
        if not self._fitted:
            raise RuntimeError("Call .fit() before .predict(), or load a saved model")

        row = self._to_feature_row(scores)
        fake_prob = float(self.model.predict_proba(row)[0, 1])

        return FusionResult(
            final_fake_probability=round(fake_prob, 4),
            verdict=_verdict_from_probability(fake_prob),
            confidence=round(abs(fake_prob - 0.5) * 2, 4),
            fusion_method="meta_classifier",
            contributing_scores=list(scores),
        )


if __name__ == "__main__":
    # quick smoke test
    demo_scores = [
        ModalityScore(modality="image", model_name="xception_deepfake_v3",
                      fake_probability=0.82, processing_time_ms=120.0),
        ModalityScore(modality="video_temporal", model_name="video_transformer_v1",
                      fake_probability=0.74, processing_time_ms=980.0),
        ModalityScore(modality="audio", model_name="wav2vec2_spoof_v2",
                      fake_probability=0.55, processing_time_ms=340.0),
    ]
    result = weighted_soft_vote(demo_scores)
    print(result.model_dump_json(indent=2))
