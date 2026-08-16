import 'package:flutter/material.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';

class HistoryView extends StatefulWidget {
  final Function(String jobId, String verdict) onViewScanDetails;

  const HistoryView({super.key, required this.onViewScanDetails});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await ApiService.fetchDashboardIntegrity();
    if (mounted) {
      setState(() {
        _scans = List<Map<String, dynamic>>.from(data['recent_scans'] ?? []);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Scan History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.neonMint),
                    onPressed: _loadHistory,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Audit logs and digital artifact verification records",
                style: TextStyle(
                  color: AppTheme.inconclusiveGray,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.neonMint))
                    : _scans.isEmpty
                        ? const Center(
                            child: Text(
                              "No past scans recorded.",
                              style: TextStyle(color: AppTheme.inconclusiveGray),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _scans.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final scan = _scans[index];
                              final scanVerdict = scan['verdict'] ?? 'AUTHENTIC';
                              final title = scan['title'] ?? 'Scan Item';
                              final time = scan['time_display'] ?? '';
                              final String? assetImg = scan['asset_image'];

                              Color pillBg;
                              Color pillText;
                              String pillLabel;

                              if (scanVerdict == 'AUTHENTIC') {
                                pillBg = AppTheme.neonMint.withValues(alpha: 0.15);
                                pillText = AppTheme.neonMint;
                                pillLabel = "• AUTHENTIC";
                              } else if (scanVerdict == 'MANIPULATED') {
                                pillBg = AppTheme.manipulatedRed.withValues(alpha: 0.15);
                                pillText = AppTheme.manipulatedRed;
                                pillLabel = "• MANIPULATED";
                              } else {
                                pillBg = const Color(0xFF1E2C3C);
                                pillText = AppTheme.inconclusiveGray;
                                pillLabel = "INCONCLUSIVE";
                              }

                              return InkWell(
                                onTap: () => widget.onViewScanDetails(scan['id'] ?? 'scan_001', scanVerdict),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardDark,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF162534),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.cardBorder),
                                          image: assetImg != null
                                              ? DecorationImage(
                                                  image: AssetImage(assetImg),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: assetImg == null
                                            ? const Icon(Icons.audio_file_rounded, color: AppTheme.inconclusiveGray, size: 26)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: pillBg,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    pillLabel,
                                                    style: TextStyle(
                                                      color: pillText,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  time,
                                                  style: const TextStyle(
                                                    color: AppTheme.inconclusiveGray,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppTheme.inconclusiveGray, size: 24),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
