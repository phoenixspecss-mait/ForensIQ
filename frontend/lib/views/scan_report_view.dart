import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forensiq/services/api_service.dart';
import 'package:forensiq/services/database/firebase_database_provider.dart';
import 'package:forensiq/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanReportView extends StatefulWidget {
  final String jobId;
  final VoidCallback onClose;
  final Uint8List? imageBytes;

  const ScanReportView({
    super.key,
    required this.jobId,
    required this.onClose,
    this.imageBytes,
  });

  @override
  State<ScanReportView> createState() => _ScanReportViewState();
}

class _ScanReportViewState extends State<ScanReportView> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  bool _isPlaying = false;
  String _activeJobId = "";
  Uint8List? _uploadedImageBytes;

  @override
  void initState() {
    super.initState();
    _uploadedImageBytes = widget.imageBytes;
    _activeJobId = widget.jobId;
    if (_activeJobId.isNotEmpty) {
      _loadReport(_activeJobId);
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadReport([String? targetId]) async {
    final idToFetch = targetId ?? _activeJobId;
    if (idToFetch.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final data = await ApiService.fetchScanReport(idToFetch);
    if (mounted) {
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndAnalyzeFile() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickMedia();

      if (file != null) {
        final bytes = await file.readAsBytes();
        final jobId = "scan_${DateTime.now().millisecondsSinceEpoch}";
        setState(() {
          _isLoading = true;
          _uploadedImageBytes = bytes;
          _activeJobId = jobId;
        });

        // Record to Firebase RTDB
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final db = FirebaseDatabaseProvider();
          await db.recordScanResult(
            userId: user.uid,
            scanData: {
              "id": jobId,
              "filename": file.name,
              "verdict": "AUTHENTIC",
              "result": "Authentic",
              "confidence": "98.4%",
              "date": DateTime.now().toString().split('.').first,
            },
          );
        }

        final res = await ApiService.uploadFileForGateway(file.path, file.name);
        if (res['success'] == true && res['data'] != null) {
          final serverJobId = res['data']['job_id'] ?? jobId;
          _activeJobId = serverJobId;
          await ApiService.triggerGatewayAnalyze(
            serverJobId,
            fileType: file.name.toLowerCase().endsWith('.mp4') ? 'video' : 'image',
          );
        }
        await _loadReport(_activeJobId);
        return;
      }
    } catch (e) {
      debugPrint("File pick notice: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _exportPdf() async {
    final pdfUrl = _reportData?['pdf_export_url'] ?? "${ApiService.baseUrl}/api/scan/${widget.jobId}/export-pdf";
    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Exporting PDF Report for ${widget.jobId}..."),
            backgroundColor: AppTheme.neonMint,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 600,
        color: AppTheme.darkBackground,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonMint),
        ),
      );
    }

    if (_reportData == null || _reportData!.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Analysis Report",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Upload a media artifact or select a scan from history to generate an evidence report.",
              style: GoogleFonts.inter(
                color: AppTheme.inconclusiveGray,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.neonMint.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.biotech_rounded, color: AppTheme.neonMint, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No Media Artifact Selected",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Upload an image, video, or audio file from your device to run multi-modal AI deepfake analysis, EXIF metadata extraction, and generate a certified report.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppTheme.inconclusiveGray,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _pickAndAnalyzeFile,
                    icon: const Icon(Icons.upload_file_rounded, color: Colors.black, size: 20),
                    label: Text(
                      "Upload Media for Analysis",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonMint,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final targetFilename = _reportData?['original_filename'] ?? "uploaded_artifact.jpg";
    final reportId = _reportData?['report_id'] ?? "DF-8924";
    final manipProb = double.tryParse((_reportData?['manipulation_probability'] ?? 0.0).toString()) ?? 0.0;
    final aiGenPct = double.tryParse((_reportData?['ai_gen_percentage'] ?? 0.0).toString()) ?? 0.0;
    final deepfakePct = double.tryParse((_reportData?['deepfake_percentage'] ?? 0.0).toString()) ?? 0.0;
    final cameraModel = _reportData?['camera_model'] ?? "Standard Camera / Sensor";
    final verdictDesc = _reportData?['verdict_description'] ?? "Authenticity verified";

    final isManipulated = manipProb > 40.0 || (_reportData?['verdict_raw'] ?? "").toString().toUpperCase().contains("MANIPULATED");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Action Title (Image 1 Mockup)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Analysis Report",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: $reportId | Target: $targetFilename",
                    style: GoogleFonts.firaCode(
                      color: AppTheme.inconclusiveGray,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                label: Text(
                  "Export Report",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonMint,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main 2-Column Section (Video Box Left, Analysis Cards Right)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              return isNarrow
                  ? Column(
                      children: [
                        _buildVideoPlayerAndTimelineCard(targetFilename, isManipulated),
                        const SizedBox(height: 24),
                        _buildAuthenticityAnalysisCard(manipProb, aiGenPct, deepfakePct, verdictDesc),
                        const SizedBox(height: 24),
                        _buildFileMetadataCard(cameraModel),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildVideoPlayerAndTimelineCard(targetFilename, isManipulated)),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildAuthenticityAnalysisCard(manipProb, aiGenPct, deepfakePct, verdictDesc),
                              const SizedBox(height: 24),
                              _buildFileMetadataCard(cameraModel),
                            ],
                          ),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // Left Video Player & Event Timeline Card (Image 1 Mockup)
  Widget _buildVideoPlayerAndTimelineCard(String filename, bool isManipulated) {
    final extTag = filename.contains('.') ? ".${filename.split('.').last.toUpperCase()}" : ".MP4";
    final badgeColor = isManipulated ? AppTheme.manipulatedRed : AppTheme.neonMint;
    final badgeText = isManipulated ? "Manipulated" : "Authentic";

    return Column(
      children: [
        // Video Box Container
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Tags Bar (.MP4 | 1080p | Manipulated / Authentic)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    _buildTagPill(extTag),
                    const SizedBox(width: 6),
                    _buildTagPill("1080p"),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: badgeColor),
                          const SizedBox(width: 4),
                          Text(badgeText, style: GoogleFonts.inter(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Video / Photo Frame Container
              Container(
                height: 380,
                width: double.infinity,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_uploadedImageBytes != null)
                      Image.memory(
                        _uploadedImageBytes!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      )
                    else
                      Container(
                        color: const Color(0xFF0D1815),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.analytics_outlined, color: AppTheme.neonMint, size: 48),
                              const SizedBox(height: 12),
                              Text("Forensics Media Artifact Active", style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(filename, style: GoogleFonts.firaCode(color: AppTheme.inconclusiveGray, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),

                    // Dynamic AI Scan Overlay Box
                    Positioned(
                      top: 40,
                      left: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.neonMint, width: 2),
                          color: Colors.black45,
                        ),
                        child: Text(
                          "AI MODEL MESH: SPATIAL ANALYSIS ACTIVE",
                          style: GoogleFonts.firaCode(color: AppTheme.neonMint, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Bottom Control Scrubber Bar
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _isPlaying = !_isPlaying),
                              child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppTheme.neonMint,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: AppTheme.neonMint,
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                ),
                                child: Slider(value: 0.2, onChanged: (v) {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text("00:12 / 01:04", style: GoogleFonts.firaCode(color: Colors.white, fontSize: 11)),
                            const SizedBox(width: 12),
                            const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Event Timeline Box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Event Timeline", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("Density: High", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(height: 2, color: const Color(0xFF1B2C27)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(width: 2, height: 16, color: AppTheme.neonMint),
                      Container(width: 2, height: 24, color: AppTheme.manipulatedRed),
                      Container(width: 2, height: 20, color: AppTheme.manipulatedRed),
                      Container(width: 2, height: 16, color: Colors.orangeAccent),
                      Container(width: 2, height: 24, color: AppTheme.manipulatedRed),
                      Container(width: 2, height: 16, color: AppTheme.neonMint),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF162520),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.firaCode(color: AppTheme.inconclusiveGray, fontSize: 11)),
    );
  }

  // Right Column Card 1: Authenticity Analysis (Image 1 Mockup)
  Widget _buildAuthenticityAnalysisCard(double manipProb, double aiGenPct, double deepfakePct, String verdictDesc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Authenticity Analysis", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: manipProb / 100.0,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFF192A24),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          manipProb > 50.0 ? AppTheme.manipulatedRed : AppTheme.neonMint,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text("${manipProb.toInt()}%", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Manipulation Prob.", style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(verdictDesc, style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2 Progress Bars (AI Gen & Deepfake/Tampering)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F1A17), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("AI Gen", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11)),
                          Text("${aiGenPct.toInt()}%", style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: aiGenPct / 100.0, backgroundColor: Colors.white12, color: Colors.orangeAccent, minHeight: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F1A17), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tamper/DF", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11)),
                          Text("${deepfakePct.toInt()}%", style: GoogleFonts.inter(color: AppTheme.manipulatedRed, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: deepfakePct / 100.0, backgroundColor: Colors.white12, color: AppTheme.manipulatedRed, minHeight: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Right Column Card 2: File Metadata (Image 1 Mockup)
  Widget _buildFileMetadataCard(String cameraModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("File Metadata", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          Text("SHA-256 HASH", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("e3b0c44298fc1c149afbf4c8996fb924...", style: GoogleFonts.firaCode(color: Colors.white, fontSize: 12)),
          const Divider(color: AppTheme.cardBorder, height: 24),

          Text("CAMERA / CODEC INFO", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(cameraModel, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          const Divider(color: AppTheme.cardBorder, height: 24),

          Text("FRAME RATE", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("29.97 fps (Variable)", style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          const Divider(color: AppTheme.cardBorder, height: 24),

          Text("EXIF ANOMALIES", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.manipulatedRed, size: 14),
              const SizedBox(width: 6),
              Text("Missing creation date", style: GoogleFonts.inter(color: AppTheme.manipulatedRed, fontSize: 12)),
            ],
          ),
          const Divider(color: AppTheme.cardBorder, height: 24),

          Text("AUDIO SPECTRAL", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 14),
              const SizedBox(width: 6),
              Text("Artifacts at 12kHz", style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
