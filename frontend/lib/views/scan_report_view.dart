import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/services/api_service.dart';
import 'package:forensiq/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanReportView extends StatefulWidget {
  final String jobId;
  final VoidCallback onClose;

  const ScanReportView({
    super.key,
    required this.jobId,
    required this.onClose,
  });

  @override
  State<ScanReportView> createState() => _ScanReportViewState();
}

class _ScanReportViewState extends State<ScanReportView> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final data = await ApiService.fetchScanReport(widget.jobId);
    if (mounted) {
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    }
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
                    "ID: ${widget.jobId.isEmpty ? 'SCAN-8924-Alpha' : widget.jobId} | Target: interview_raw_04.mp4",
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
                        _buildVideoPlayerAndTimelineCard(),
                        const SizedBox(height: 24),
                        _buildAuthenticityAnalysisCard(),
                        const SizedBox(height: 24),
                        _buildFileMetadataCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildVideoPlayerAndTimelineCard()),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildAuthenticityAnalysisCard(),
                              const SizedBox(height: 24),
                              _buildFileMetadataCard(),
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
  Widget _buildVideoPlayerAndTimelineCard() {
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
              // Top Tags Bar (.MP4 | 1080p | Manipulated)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    _buildTagPill(".MP4"),
                    const SizedBox(width: 6),
                    _buildTagPill("1080p"),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.manipulatedRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 3, backgroundColor: AppTheme.manipulatedRed),
                          const SizedBox(width: 4),
                          Text("Manipulated", style: GoogleFonts.inter(color: AppTheme.manipulatedRed, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Video Frame with Overlay Annotations
              Container(
                height: 380,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/state_union.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Face Bounding Box 1 (MANIPULATION DETECTED: LIP-SYNC)
                    Positioned(
                      top: 60,
                      left: 120,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.manipulatedRed, width: 2),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            color: AppTheme.manipulatedRed,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              "MANIPULATION DETECTED: LIP-SYNC",
                              style: GoogleFonts.firaCode(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Face Bounding Box 2 (ANOMALY: LIGHTING INCONSISTENCY)
                    Positioned(
                      top: 130,
                      left: 270,
                      child: Container(
                        width: 100,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orangeAccent, width: 2),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            color: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              "ANOMALY: LIGHTING INCONSISTENCY",
                              style: GoogleFonts.firaCode(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
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
  Widget _buildAuthenticityAnalysisCard() {
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
                    const SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: 0.82,
                        strokeWidth: 6,
                        backgroundColor: Color(0xFF192A24),
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.manipulatedRed),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text("82%", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    Text("High confidence of alteration", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2 Progress Bars (AI Gen 64% | Deepfake 91%)
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
                          Text("64%", style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: 0.64, backgroundColor: Colors.white12, color: Colors.orangeAccent, minHeight: 4),
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
                          Text("Deepfake", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11)),
                          Text("91%", style: GoogleFonts.inter(color: AppTheme.manipulatedRed, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: 0.91, backgroundColor: Colors.white12, color: AppTheme.manipulatedRed, minHeight: 4),
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
  Widget _buildFileMetadataCard() {
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

          Text("CODEC INFO", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("H.264 (High Profile) / AAC", style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
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
