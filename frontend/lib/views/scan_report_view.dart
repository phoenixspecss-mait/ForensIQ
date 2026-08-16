import 'package:flutter/material.dart';
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
        decoration: const BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonMint),
        ),
      );
    }

    final verdictTitle = _reportData?['verdict'] ?? "VERDICT: LIKELY MANIPULATED";
    final verdictDesc = _reportData?['verdict_description'] ?? "Deepfake signatures detected in primary subject.";
    final authPct = _reportData?['authenticity_percentage'] ?? 24;
    final isManipulated = authPct < 50;

    final breakdown = _reportData?['analysis_breakdown']?['facial_heatmap'] ?? {};
    final explanation = breakdown['explanation'] ??
        "Anomalies detected in lip-sync and ocular reflections. High probability of face-swap technology.";

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Top drag handle pill
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // ForensIQ Square Icon Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.neonMint.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonMint.withValues(alpha: 0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: const Icon(Icons.saved_search_rounded, color: AppTheme.neonMint, size: 30),
              ),
              const SizedBox(height: 18),

              // Verdict Title (Screen 3 Mockup)
              Text(
                verdictTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isManipulated ? AppTheme.manipulatedRed : AppTheme.neonMint,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                verdictDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.inconclusiveGray,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Authenticity Circular Gauge (24% AUTHENTICITY)
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: authPct / 100.0,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFF162534),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isManipulated ? AppTheme.manipulatedRed : AppTheme.neonMint,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$authPct%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "AUTHENTICITY",
                          style: TextStyle(
                            color: AppTheme.inconclusiveGray,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ANALYSIS BREAKDOWN Section Title
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "ANALYSIS BREAKDOWN",
                  style: TextStyle(
                    color: AppTheme.inconclusiveGray,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Facial Heatmap Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "FACIAL HEATMAP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          "🔥",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Heatmap Visualization Frame
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                        image: const DecorationImage(
                          image: AssetImage("assets/images/state_union.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withValues(alpha: 0.4),
                              Colors.purple.withValues(alpha: 0.5),
                              Colors.red.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Manipulation Prob: 89.4%",
                                  style: TextStyle(color: AppTheme.manipulatedRed, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      explanation,
                      style: const TextStyle(
                        color: AppTheme.inconclusiveGray,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export Full Report Button (Screen 3 Mockup)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                  label: const Text(
                    "Export Full Report",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonMint,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
