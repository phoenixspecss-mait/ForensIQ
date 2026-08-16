import 'package:flutter/material.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';

class DashboardView extends StatefulWidget {
  final VoidCallback onStartScanPressed;
  final Function(String jobId, String type) onViewScanDetails;

  const DashboardView({
    super.key,
    required this.onStartScanPressed,
    required this.onViewScanDetails,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final data = await ApiService.fetchDashboardIntegrity();
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.neonMint),
        ),
      );
    }

    final integrityPct = _dashboardData?['system_integrity_percentage'] ?? 98;
    final verdict = _dashboardData?['verdict'] ?? 'AUTHENTIC';
    final lastScan = _dashboardData?['last_scan_time'] ?? '2 MINS AGO';
    final threatLevel = _dashboardData?['threat_level'] ?? 'MINIMAL';
    final List recentScans = _dashboardData?['recent_scans'] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar (User Avatar, ForensIQ Logo, Notification Bell)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // User Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/creator_icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // ForensIQ Brand Logo & Text
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.neonMint.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.saved_search_rounded, color: AppTheme.neonMint, size: 22),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "ForensIQ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Notification Bell with Badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.neonMint,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // OVERALL SYSTEM INTEGRITY Hero Card (Screen 1 Mockup)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Card Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "OVERALL SYSTEM INTEGRITY",
                          style: TextStyle(
                            color: Color(0xFF9EACB9),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.neonMint.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppTheme.neonMint, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Big Circular Gauge (98% AUTHENTIC)
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Ring track
                          SizedBox(
                            width: 165,
                            height: 165,
                            child: CircularProgressIndicator(
                              value: integrityPct / 100,
                              strokeWidth: 12,
                              backgroundColor: const Color(0xFF162534),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonMint),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$integrityPct%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                verdict,
                                style: const TextStyle(
                                  color: AppTheme.neonMint,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Divider(color: AppTheme.cardBorder, height: 1),
                    const SizedBox(height: 16),

                    // Stats Row Footer (LAST SCAN & THREAT LEVEL)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "LAST SCAN",
                              style: TextStyle(
                                color: AppTheme.inconclusiveGray,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastScan,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "THREAT LEVEL",
                              style: TextStyle(
                                color: AppTheme.inconclusiveGray,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              threatLevel,
                              style: const TextStyle(
                                color: AppTheme.neonMint,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Recent Scans Header
              const Text(
                "Recent Scans",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Recent Scans List Items
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentScans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final scan = recentScans[index];
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          // Media Thumbnail / Icon
                          Container(
                            width: 64,
                            height: 64,
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
                                ? const Icon(Icons.audio_file_rounded, color: AppTheme.inconclusiveGray, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 14),

                          // Title and Status Pill
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: pillBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        pillLabel,
                                        style: TextStyle(
                                          color: pillText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        color: AppTheme.inconclusiveGray,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Right Chevron Arrow
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.inconclusiveGray, size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 80), // Padding for floating scan button
            ],
          ),
        ),
      ),
    );
  }
}
