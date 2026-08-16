import 'package:flutter/material.dart';
import 'package:forensiq/services/api_service.dart';
import 'package:forensiq/theme/app_theme.dart';

class CertificateView extends StatefulWidget {
  final String jobId;
  final VoidCallback onClose;

  const CertificateView({
    super.key,
    required this.jobId,
    required this.onClose,
  });

  @override
  State<CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<CertificateView> {
  Map<String, dynamic>? _certData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    final data = await ApiService.fetchVerificationCertificate(widget.jobId);
    if (mounted) {
      setState(() {
        _certData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 500,
        decoration: const BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonMint),
        ),
      );
    }

    final authPct = _certData?['authenticity_percentage'] ?? 99;
    final statusText = _certData?['status'] ?? "VERIFIED";
    final scanDate = _certData?['scan_date'] ?? "2023-10-27 14:32Z";

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag bar
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // ForensIQ Square Icon Badge (Screen 4 Mockup)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.neonMint.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonMint.withValues(alpha: 0.15),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: const Icon(Icons.saved_search_rounded, color: AppTheme.neonMint, size: 36),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                "ForensIQ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              // Large Circular Authentic Ring Meter (Screen 4 Mockup)
              SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: authPct / 100.0,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFF162534),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonMint),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.neonMint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.black, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$authPct%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Authentic",
                          style: TextStyle(
                            color: AppTheme.neonMint,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Certificate Metadata Details Card (Screen 4 Mockup)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.verified_user_rounded, color: AppTheme.neonMint, size: 18),
                            SizedBox(width: 10),
                            Text(
                              "STATUS",
                              style: TextStyle(
                                color: AppTheme.inconclusiveGray,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: AppTheme.neonMint,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppTheme.cardBorder, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "SCAN DATE",
                          style: TextStyle(
                            color: AppTheme.inconclusiveGray,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          scanDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
