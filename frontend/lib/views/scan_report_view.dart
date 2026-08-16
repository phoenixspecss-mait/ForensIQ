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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return isNarrow
              ? Column(
                  children: [
                    _buildVideoPreviewCard(),
                    const SizedBox(height: 24),
                    _buildConfidenceBreakdownCard(),
                    const SizedBox(height: 24),
                    _buildTechnicalMetadataCard(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildVideoPreviewCard()),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildConfidenceBreakdownCard(),
                          const SizedBox(height: 24),
                          _buildTechnicalMetadataCard(),
                        ],
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  // Video Player Preview Box (Screen 1 Mockup)
  Widget _buildVideoPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Frame Container
          Container(
            height: 380,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: const DecorationImage(
                image: AssetImage("assets/images/state_union.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Top-Right MANIPULATED Red Badge (Screen 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.manipulatedRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "MANIPULATED",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                // Video Scrubber & Play Bar at Bottom (Screen 1)
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _isPlaying = !_isPlaying),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.neonMint,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: AppTheme.neonMint,
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: 0.35,
                              onChanged: (v) {},
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File Info Footer Bar (Screen 1)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "video_123.mp4",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Size: 54 MB",
                  style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3 Circular Percentage Rings (Screen 1 Mockup)
  Widget _buildConfidenceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Confidence Breakdown",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGaugeRing("98%", "Manipulation\nDetected"),
              _buildGaugeRing("75%", "AI-Generated\nContent"),
              _buildGaugeRing("92%", "Deepfake\nProbability"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeRing(String pct, String label) {
    final val = (double.tryParse(pct.replaceAll('%', '')) ?? 80) / 100.0;
    return Column(
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: val,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFF162520),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonMint),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                pct,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppTheme.inconclusiveGray,
            fontSize: 11,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // Technical Metadata Card & Export Report Cyan Button (Screen 1 Mockup)
  Widget _buildTechnicalMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Technical Metadata",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.inconclusiveGray, size: 18),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.inconclusiveGray, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaRow("Frame Rate", "30 fps"),
          _buildMetaRow("Resolution", "1920x1080"),
          _buildMetaRow("Codec", "H 264"),
          _buildMetaRow("Creation Date", "2023-10-27 14:30:00"),
          const SizedBox(height: 24),

          // EXPORT REPORT Cyan Button (Screen 1)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.download_rounded, color: Colors.black, size: 18),
              label: Text(
                "EXPORT REPORT",
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonMint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
          Text(val, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
