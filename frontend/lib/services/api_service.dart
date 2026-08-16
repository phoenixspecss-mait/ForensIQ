import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL', defaultValue: String.fromEnvironment('BACKEND_URL'));
    if (customUrl.isNotEmpty) return customUrl;
    if (kIsWeb) return "http://localhost:8000";
    return "http://10.0.2.2:8000";
  }

  // 1. Dashboard Integrity (Screen 1)
  static Future<Map<String, dynamic>> fetchDashboardIntegrity() async {
    try {
      final url = Uri.parse("$baseUrl/api/dashboard/integrity");
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("fetchDashboardIntegrity error: $e");
    }
    // Fallback data matching Screen 1 mockup
    return {
      "system_integrity_percentage": 98,
      "verdict": "AUTHENTIC",
      "last_scan_time": "2 MINS AGO",
      "threat_level": "MINIMAL",
      "threat_level_color": "#00E699",
      "recent_scans": [
        {
          "id": "scan_001",
          "title": "State of the Union Excerpt",
          "verdict": "AUTHENTIC",
          "time_display": "10:42 AM",
          "media_type": "video",
          "asset_image": "assets/images/state_union.jpg"
        },
        {
          "id": "scan_002",
          "title": "Viral Twitter Image",
          "verdict": "MANIPULATED",
          "time_display": "YESTERDAY",
          "media_type": "image",
          "asset_image": "assets/images/twitter_image.jpg"
        },
        {
          "id": "scan_003",
          "title": "Leaked Earnings Call.wav",
          "verdict": "INCONCLUSIVE",
          "time_display": "OCT 12",
          "media_type": "audio",
          "asset_image": null
        }
      ]
    };
  }

  // 2. Active DeepScan Progress (Screen 2)
  static Future<Map<String, dynamic>> fetchScanProgress(String jobId) async {
    try {
      final url = Uri.parse("$baseUrl/api/scan/$jobId/progress");
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("fetchScanProgress error: $e");
    }
    // Fallback matching Screen 2 mockup
    return {
      "job_id": jobId,
      "title": "DeepScan Analysis",
      "subtitle": "Verifying digital artifact integrity. Do not close this window.",
      "overall_progress_percentage": 65,
      "status_text": "Scanning...",
      "active_frame_info": {
        "analysis_active": true,
        "frame_timestamp": "00:14:32",
        "frame_hex": "0x4F92A",
        "asset_image": "assets/images/state_union.jpg"
      },
      "pipeline_steps": [
        {
          "step_id": "metadata",
          "name": "Extracting Metadata",
          "status": "completed",
          "details": "OK - 0.4s"
        },
        {
          "step_id": "face_analysis",
          "name": "Analyzing Faces...",
          "status": "in_progress",
          "details": "Scanning facial landmarks & biometrics"
        },
        {
          "step_id": "audio_processing",
          "name": "Processing Audio...",
          "status": "pending",
          "details": "Awaiting frame alignment"
        }
      ],
      "encryption": "End-to-end encrypted analysis.",
      "can_boost": true,
      "can_cancel": true
    };
  }

  // 3. Scan Verdict & Detailed Analysis Report (Screen 3)
  static Future<Map<String, dynamic>> fetchScanReport(String jobId) async {
    try {
      final url = Uri.parse("$baseUrl/api/scan/$jobId/report");
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("fetchScanReport error: $e");
    }
    // Fallback matching Screen 3 mockup
    return {
      "report_id": "DF-7734",
      "verdict": "VERDICT: LIKELY MANIPULATED",
      "verdict_raw": "LIKELY_MANIPULATED",
      "verdict_description": "Deepfake signatures detected in primary subject.",
      "authenticity_percentage": 24,
      "analysis_breakdown": {
        "facial_heatmap": {
          "title": "FACIAL HEATMAP",
          "asset_image": "assets/images/state_union.jpg",
          "manipulation_probability": 89.4,
          "thermal_variances": ["+2.3°C (Eyes)", "+3.1°C (Mouth)"],
          "explanation": "Anomalies detected in lip-sync and ocular reflections. High probability of face-swap technology."
        }
      },
      "pdf_export_url": "$baseUrl/api/scan/$jobId/export-pdf"
    };
  }

  // 4. Verification Certificate (Screen 4)
  static Future<Map<String, dynamic>> fetchVerificationCertificate(String jobId) async {
    try {
      final url = Uri.parse("$baseUrl/api/scan/$jobId/certificate");
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("fetchVerificationCertificate error: $e");
    }
    // Fallback matching Screen 4 mockup
    return {
      "certificate_id": "VER-2023-1027-$jobId",
      "authenticity_percentage": 99,
      "verdict": "Authentic",
      "status": "VERIFIED",
      "scan_date": "2023-10-27 14:32Z",
      "is_valid": true
    };
  }

  // Gateway Upload and Full Analysis Workflow
  static Future<Map<String, dynamic>> uploadFileForGateway(String filePath, String fileName) async {
    try {
      final uri = Uri.parse("$baseUrl/gateway/upload");
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body);

      if (streamed.statusCode == 200) {
        return {"success": true, "data": data};
      }
      return {"success": false, "message": data['detail'] ?? 'Upload failed'};
    } catch (e) {
      debugPrint('uploadFileForGateway error: $e');
      return {"success": false, "message": 'Could not connect to backend server'};
    }
  }

  static Future<Map<String, dynamic>> triggerGatewayAnalyze(String jobId, {String fileType = "image"}) async {
    try {
      final url = Uri.parse("$baseUrl/gateway/$jobId/analyze?file_type=$fileType");
      final response = await http.post(url).timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
    } catch (e) {
      debugPrint('triggerGatewayAnalyze error: $e');
    }
    return {"success": false, "message": "Analysis queued locally"};
  }

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final url = Uri.parse("$baseUrl/health");
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {"status": "offline"};
  }
}
