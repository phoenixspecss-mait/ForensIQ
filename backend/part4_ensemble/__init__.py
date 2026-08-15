"""Part 4: Ensemble, Grad-CAM & Reports - Main Forensics Decision Engine"""

import torch
import torch.nn as nn
import numpy as np
from typing import Dict, List, Tuple
from dataclasses import dataclass
from datetime import datetime
import json


@dataclass
class ForensicsReport:
    """Structured forensics analysis report"""
    timestamp: str
    input_file: str
    file_type: str  # 'image', 'video'
    
    # Part 2 (Image Forensics)
    track_a_synthetic_prob: float  # REAL vs AI-GENERATED
    track_b_tampered_prob: float   # REAL vs MANIPULATED
    track_c_prnu_match: float      # Camera sensor verification
    
    # Part 3 (Video & Audio Forensics)
    video_anomaly_score: float
    audio_anomaly_score: float
    
    # Ensemble Decision
    final_verdict: str  # "AUTHENTIC", "AI_GENERATED", "TAMPERED", "UNKNOWN"
    confidence_score: float
    risk_level: str  # "LOW", "MEDIUM", "HIGH", "CRITICAL"
    
    # Explanations
    primary_indicators: List[str]
    secondary_indicators: List[str]
    recommendations: List[str]
    
    def to_dict(self):
        """Convert to dictionary for JSON serialization"""
        return {
            "timestamp": self.timestamp,
            "input_file": self.input_file,
            "file_type": self.file_type,
            "track_a_synthetic_prob": round(self.track_a_synthetic_prob, 4),
            "track_b_tampered_prob": round(self.track_b_tampered_prob, 4),
            "track_c_prnu_match": round(self.track_c_prnu_match, 4),
            "video_anomaly_score": round(self.video_anomaly_score, 4),
            "audio_anomaly_score": round(self.audio_anomaly_score, 4),
            "final_verdict": self.final_verdict,
            "confidence_score": round(self.confidence_score, 4),
            "risk_level": self.risk_level,
            "primary_indicators": self.primary_indicators,
            "secondary_indicators": self.secondary_indicators,
            "recommendations": self.recommendations,
        }


class EnsembleForensicsEngine:
    """
    Multimodal forensics ensemble combining:
    - Part 2: Image AI & Pixel Forensics (3 tracks)
    - Part 3: Video Biometrics & Audio AI
    """
    
    def __init__(self, weights: Dict[str, float] = None):
        """
        Args:
            weights: Weighted voting scheme
                {
                    'track_a': 0.25,      # Synthetic media detection
                    'track_b': 0.25,      # Image tampering detection
                    'track_c': 0.15,      # PRNU camera verification
                    'video': 0.20,        # Video biometrics
                    'audio': 0.15         # Audio deepfake detection
                }
        """
        self.weights = weights or {
            'track_a': 0.25,
            'track_b': 0.25,
            'track_c': 0.15,
            'video': 0.20,
            'audio': 0.15
        }
        
        # Validate weights sum to 1.0
        assert abs(sum(self.weights.values()) - 1.0) < 0.01, "Weights must sum to 1.0"
    
    def analyze_image(
        self,
        image_path: str,
        track_a_pred: float,
        track_b_pred: float,
        track_c_pred: float
    ) -> ForensicsReport:
        """
        Analyze a single image using Part 2 tracks
        
        Args:
            image_path: Path to image
            track_a_pred: Probability of AI-generation [0, 1]
            track_b_pred: Probability of tampering [0, 1]
            track_c_pred: PRNU camera match score [0, 1]
        
        Returns:
            ForensicsReport with ensemble decision
        """
        # Weighted ensemble vote (image only)
        image_weights = {
            'track_a': 0.4,
            'track_b': 0.4,
            'track_c': 0.2
        }
        
        ensemble_score = (
            image_weights['track_a'] * track_a_pred +
            image_weights['track_b'] * track_b_pred +
            image_weights['track_c'] * (1 - track_c_pred)  # Invert: high PRNU = more authentic
        )
        
        # Determine verdict
        primary_indicators = []
        secondary_indicators = []
        
        if track_a_pred > 0.7:
            primary_indicators.append(f"High AI-generation probability ({track_a_pred:.2%})")
        if track_b_pred > 0.7:
            primary_indicators.append(f"High tampering probability ({track_b_pred:.2%})")
        if track_c_pred < 0.3:
            secondary_indicators.append(f"Low PRNU camera match ({track_c_pred:.2%})")
        
        # Generate verdict
        if ensemble_score > 0.75:
            verdict = "TAMPERED" if track_b_pred > track_a_pred else "AI_GENERATED"
            confidence = ensemble_score
            risk = "CRITICAL"
        elif ensemble_score > 0.55:
            verdict = "TAMPERED" if track_b_pred > track_a_pred else "AI_GENERATED"
            confidence = ensemble_score
            risk = "HIGH"
        elif ensemble_score > 0.35:
            verdict = "UNKNOWN"
            confidence = 1 - abs(0.5 - ensemble_score)
            risk = "MEDIUM"
        else:
            verdict = "AUTHENTIC"
            confidence = 1 - ensemble_score
            risk = "LOW"
        
        recommendations = self._generate_recommendations(verdict, risk, primary_indicators)
        
        return ForensicsReport(
            timestamp=datetime.now().isoformat(),
            input_file=image_path,
            file_type="image",
            track_a_synthetic_prob=track_a_pred,
            track_b_tampered_prob=track_b_pred,
            track_c_prnu_match=track_c_pred,
            video_anomaly_score=0.0,
            audio_anomaly_score=0.0,
            final_verdict=verdict,
            confidence_score=confidence,
            risk_level=risk,
            primary_indicators=primary_indicators,
            secondary_indicators=secondary_indicators,
            recommendations=recommendations
        )
    
    def analyze_video(
        self,
        video_path: str,
        video_biometrics: Dict,
        audio_forensics: Dict,
        track_a_pred: float = None,
        track_b_pred: float = None
    ) -> ForensicsReport:
        """
        Analyze a video using Part 3 (and optionally Part 2 frame analysis)
        
        Args:
            video_path: Path to video
            video_biometrics: Dict with video_anomaly_score
            audio_forensics: Dict with audio_anomaly_score
            track_a_pred: Optional frame-level AI generation probability
            track_b_pred: Optional frame-level tampering probability
        
        Returns:
            ForensicsReport with ensemble decision
        """
        
        v_score = video_biometrics.get("video_anomaly_score", 0.5)
        a_score = audio_forensics.get("audio_anomaly_score", 0.5)
        
        # Multimodal fusion (Part 3)
        part3_score = 0.6 * v_score + 0.4 * a_score
        
        # Optional: incorporate Part 2 frame analysis
        if track_a_pred is not None and track_b_pred is not None:
            part3_score = 0.7 * part3_score + 0.15 * track_a_pred + 0.15 * track_b_pred
        
        primary_indicators = []
        secondary_indicators = []
        
        if v_score > 0.7:
            primary_indicators.append(f"Video biometric anomalies detected ({v_score:.2%})")
        if a_score > 0.7:
            primary_indicators.append(f"Audio deepfake indicators ({a_score:.2%})")
        
        # Extract detailed metrics
        ear_variance = video_biometrics.get("ear_variance", 0)
        blink_variance = video_biometrics.get("blink_blendshape_variance", 0)
        jitter = video_biometrics.get("head_jitter_metric", 0)
        
        if ear_variance < 0.001:
            secondary_indicators.append("Frozen eye aspect ratio (sign of deepfake)")
        if blink_variance < 0.002:
            secondary_indicators.append("Unnatural blink pattern")
        if jitter > 0.05:
            secondary_indicators.append("High head jitter (erratic movement)")
        
        # Verdict
        if part3_score > 0.75:
            verdict = "AI_GENERATED"
            confidence = part3_score
            risk = "CRITICAL"
        elif part3_score > 0.55:
            verdict = "AI_GENERATED"
            confidence = part3_score
            risk = "HIGH"
        elif part3_score > 0.35:
            verdict = "UNKNOWN"
            confidence = 1 - abs(0.5 - part3_score)
            risk = "MEDIUM"
        else:
            verdict = "AUTHENTIC"
            confidence = 1 - part3_score
            risk = "LOW"
        
        recommendations = self._generate_recommendations(verdict, risk, primary_indicators)
        
        return ForensicsReport(
            timestamp=datetime.now().isoformat(),
            input_file=video_path,
            file_type="video",
            track_a_synthetic_prob=track_a_pred or 0.0,
            track_b_tampered_prob=track_b_pred or 0.0,
            track_c_prnu_match=0.0,
            video_anomaly_score=v_score,
            audio_anomaly_score=a_score,
            final_verdict=verdict,
            confidence_score=confidence,
            risk_level=risk,
            primary_indicators=primary_indicators,
            secondary_indicators=secondary_indicators,
            recommendations=recommendations
        )
    
    def _generate_recommendations(
        self,
        verdict: str,
        risk_level: str,
        indicators: List[str]
    ) -> List[str]:
        """Generate actionable recommendations based on verdict and risk"""
        
        recommendations = []
        
        if verdict == "AI_GENERATED":
            recommendations.append("⚠️ Content appears to be synthetically generated")
            recommendations.append("Flag for fact-checking and source verification")
            recommendations.append("Consider requesting raw file metadata")
        
        elif verdict == "TAMPERED":
            recommendations.append("⚠️ Image/video shows signs of manipulation")
            recommendations.append("Localized tampering detected - review high-risk regions")
            recommendations.append("Request chain of custody documentation")
        
        elif verdict == "UNKNOWN":
            recommendations.append("⚠️ Analysis inconclusive - manual review recommended")
            recommendations.append("Collect additional metadata (EXIF, headers, source)")
            recommendations.append("Perform supplementary forensic analysis")
        
        else:  # AUTHENTIC
            recommendations.append("✓ Content appears authentic")
            recommendations.append("No major forensic red flags detected")
        
        # Risk-based recommendations
        if risk_level == "CRITICAL":
            recommendations.append("🚨 URGENT: Escalate to forensics specialist")
            recommendations.append("Preserve all original file bytes")
        
        elif risk_level == "HIGH":
            recommendations.append("Escalate for secondary analysis")
        
        return recommendations
    
    def generate_json_report(self, report: ForensicsReport, output_path: str = None) -> str:
        """
        Generate JSON report
        
        Args:
            report: ForensicsReport object
            output_path: Optional file path to save JSON
        
        Returns:
            JSON string
        """
        json_str = json.dumps(report.to_dict(), indent=2)
        
        if output_path:
            with open(output_path, 'w') as f:
                f.write(json_str)
            print(f"✅ Report saved: {output_path}")
        
        return json_str


# Singleton instance
_engine = None

def get_ensemble_engine() -> EnsembleForensicsEngine:
    """Get or create singleton ensemble engine"""
    global _engine
    if _engine is None:
        _engine = EnsembleForensicsEngine()
    return _engine
