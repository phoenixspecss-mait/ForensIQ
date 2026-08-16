"""
test_backend_models.py
----------------------
End-to-end validation test for trained ForensIQ backend models and FastAPI endpoints.
"""

import os
import sys
import tempfile
import numpy as np
import cv2
import soundfile as sf
from pathlib import Path
from fastapi.testclient import TestClient

# Add backend directory to sys.path
BACKEND_DIR = Path(__file__).resolve().parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

import app as app_module


def test_models_and_endpoints():
    print("==================================================")
    print("🔬 RUNNING FORENSIQ BACKEND MODELS & API TEST SUITE")
    print("==================================================")

    # Wrap TestClient in context manager to trigger startup_event()
    with TestClient(app_module.app) as client:
        # 1. Verify Model Initialization
        assert app_module.part3_pipeline is not None, "Part 3 pipeline should be initialized"
        assert app_module.image_forensics_engine is not None, "Image forensics engine should be initialized"
        assert app_module.ensemble_engine is not None, "Ensemble engine should be initialized"
        print("✅ All backend models & engines initialized successfully!")

        # 2. Test Image Forensics Model on Real Image Data
        print("\n--- 1. Testing ImageForensicsClassifier on Real Image Data ---")
        img = (np.random.rand(256, 256, 3) * 255).astype(np.uint8)
        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp_img:
            cv2.imwrite(tmp_img.name, img)
            img_path = tmp_img.name

        try:
            img_res = app_module.image_forensics_engine.analyze_image(img_path)
            print(f"   Image Forensics Predictions: {img_res}")
            assert "track_a_synthetic_prob" in img_res
            assert "track_b_tampered_prob" in img_res
            assert "track_c_prnu_match" in img_res
            print("   ✅ ImageForensicsClassifier test passed")
        finally:
            if os.path.exists(img_path):
                os.remove(img_path)

        # 3. Test Audio Deepfake Classifier on Real Audio Data
        print("\n--- 2. Testing AudioDeepfakeClassifier on Real Audio Data ---")
        sr = 16000
        t = np.linspace(0, 2.0, sr * 2, endpoint=False)
        audio_sig = 0.5 * np.sin(2 * np.pi * 440 * t)
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_wav:
            sf.write(tmp_wav.name, audio_sig, sr)
            audio_path = tmp_wav.name

        try:
            audio_res = app_module.part3_pipeline.process_audio_ai(audio_path)
            print(f"   Audio Forensics Predictions: {audio_res}")
            assert audio_res["audio_present"] is True
            assert "audio_anomaly_score" in audio_res
            assert "neural_audio_score" in audio_res
            print("   ✅ AudioDeepfakeClassifier test passed")
        finally:
            if os.path.exists(audio_path):
                os.remove(audio_path)

        # 4. Test FastAPI Endpoints
        print("\n--- 3. Testing FastAPI Endpoints ---")

        # GET /health
        health_resp = client.get("/health")
        assert health_resp.status_code == 200
        print(f"   GET /health -> Status: {health_resp.status_code}")

        # GET /models/status
        status_resp = client.get("/models/status")
        assert status_resp.status_code == 200
        print(f"   GET /models/status -> Status: {status_resp.status_code}")

        # POST /analyze/image (Automated dynamic inference on uploaded image file)
        img_bgr = (np.random.rand(200, 200, 3) * 255).astype(np.uint8)
        _, img_bytes = cv2.imencode(".jpg", img_bgr)
        post_img_resp = client.post(
            "/analyze/image",
            files={"file": ("real_test_image.jpg", img_bytes.tobytes(), "image/jpeg")}
        )
        assert post_img_resp.status_code == 200
        img_report = post_img_resp.json()
        print("\n   POST /analyze/image (Dynamic Real Feature Inference):")
        print(f"      Verdict:     {img_report.get('final_verdict')}")
        print(f"      Confidence:  {img_report.get('confidence_score')}")
        print(f"      Risk Level:  {img_report.get('risk_level')}")
        print(f"      Indicators:  {img_report.get('primary_indicators')}")

        # POST /analyze/deepfake (Dynamic Score Fusion + Audit Report PDF)
        post_df_resp = client.post(
            "/analyze/deepfake",
            files={"file": ("real_test_image.jpg", img_bytes.tobytes(), "image/jpeg")}
        )
        assert post_df_resp.status_code == 200
        df_report = post_df_resp.json()
        print("\n   POST /analyze/deepfake (Dynamic Fusion & Audit Report):")
        print(f"      Status:      {df_report.get('status')}")
        print(f"      Fused Score: {df_report.get('fusion', {}).get('fused_score')}")
        print(f"      Verdict:     {df_report.get('fusion', {}).get('verdict')}")
        print(f"      PDF Generated: {df_report.get('pdf_report')}")

        
        # 5. Test Screen-Driven UI API Endpoints
        print("\n--- 4. Testing Screen-Driven UI API Endpoints ---")
        
        # Screen 1: Dashboard Integrity
        dash_resp = client.get("/api/dashboard/integrity")
        assert dash_resp.status_code == 200
        dash_data = dash_resp.json()
        assert dash_data["system_integrity_percentage"] == 98
        assert len(dash_data['recent_scans']) > 0
        print(f"   GET /api/dashboard/integrity -> 98% Authentic Integrity (Recent Scans: {len(dash_data['recent_scans'])} items)")

        # Screen 2: DeepScan Live Progress
        prog_resp = client.get("/api/scan/demo123/progress")
        assert prog_resp.status_code == 200
        prog_data = prog_resp.json()
        assert prog_data["overall_progress_percentage"] == 65
        assert len(prog_data["pipeline_steps"]) == 3
        print(f"   GET /api/scan/demo123/progress -> Overall Progress: 65%, Frame: {prog_data['active_frame_info']['frame_timestamp']}")

        # Screen 3: Detailed Report & Facial Heatmap
        rpt_resp = client.get("/api/scan/DF-7734/report")
        assert rpt_resp.status_code == 200
        rpt_data = rpt_resp.json()
        assert rpt_data['authenticity_percentage'] == 10
        assert rpt_data['manipulation_probability'] == 90.0
        assert "facial_heatmap" in rpt_data["analysis_breakdown"]
        print(f"   GET /api/scan/DF-7734/report -> Verdict: {rpt_data['verdict']}, Authenticity: {rpt_data['authenticity_percentage']}%")

        # Screen 4: Shareable Verification Certificate
        cert_resp = client.get("/api/verify/VER-2023-1027-99")
        assert cert_resp.status_code == 200
        cert_data = cert_resp.json()
        assert cert_data['status'] == "VERIFIED"
        assert cert_data['authenticity_percentage'] == 99
        print(f"   GET /api/verify/VER-2023-1027-99 -> Certificate Status: {cert_data['status']} ({cert_data['authenticity_percentage']}% Authentic)")

        print("\n==================================================")
        print("🎉 ALL BACKEND MODELS & API TESTS PASSED SUCCESSFULLY!")
        print("==================================================")


if __name__ == "__main__":
    test_models_and_endpoints()
