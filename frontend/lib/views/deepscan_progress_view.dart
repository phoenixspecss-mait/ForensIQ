import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';

class DeepScanProgressView extends StatefulWidget {
  final String jobId;
  final VoidCallback onScanCompleted;
  final VoidCallback onCancel;

  const DeepScanProgressView({
    super.key,
    required this.jobId,
    required this.onScanCompleted,
    required this.onCancel,
  });

  @override
  State<DeepScanProgressView> createState() => _DeepScanProgressViewState();
}

class _DeepScanProgressViewState extends State<DeepScanProgressView> {
  double _progress = 0.65;
  Timer? _timer;
  Map<String, dynamic>? _scanData;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _startSimulatedScan();
  }

  Future<void> _loadProgress() async {
    final data = await ApiService.fetchScanProgress(widget.jobId);
    if (mounted) {
      setState(() {
        _scanData = data;
        _progress = (data['overall_progress_percentage'] ?? 65) / 100.0;
      });
    }
  }

  void _startSimulatedScan() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted) return;
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.05;
        } else {
          _timer?.cancel();
          widget.onScanCompleted();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _scanData?['title'] ?? "DeepScan Analysis";
    final subtitle = _scanData?['subtitle'] ?? "Verifying digital artifact integrity. Do not close this window.";
    final int pctInt = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Section
              Center(
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.inconclusiveGray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Frame HUD Analysis Preview Card (Screen 2 Mockup)
              Container(
                width: double.infinity,
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/state_union.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Dark video overlay gradient
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),

                    // Top HUD status bar
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ANALYSIS ACTIVE Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.manipulatedRed.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.manipulatedRed.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.circle, color: AppTheme.manipulatedRed, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  "ANALYSIS ACTIVE",
                                  style: TextStyle(
                                    color: AppTheme.manipulatedRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // FRAME & HEX
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                "FRAME: 00:14:32",
                                style: TextStyle(
                                  color: AppTheme.neonMint,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                "HEX: 0x4F92A",
                                style: TextStyle(
                                  color: AppTheme.neonMint,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Center Face Detection Target Reticle
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.neonMint.withValues(alpha: 0.6), width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.neonMint, width: 1),
                              ),
                            ),
                            const Icon(Icons.center_focus_weak_rounded, color: AppTheme.neonMint, size: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // OVERALL PROGRESS Card (Screen 2 Mockup)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "OVERALL PROGRESS",
                      style: TextStyle(
                        color: AppTheme.inconclusiveGray,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "$pctInt%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Scanning...",
                          style: TextStyle(
                            color: AppTheme.neonMint,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Mint Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF162534),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonMint),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pipeline Steps List
                    _buildStepItem(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppTheme.neonMint,
                      title: "Extracting Metadata",
                      details: "OK - 0.4s",
                      isCompleted: true,
                    ),
                    const SizedBox(height: 12),

                    _buildStepItem(
                      icon: Icons.sync_rounded,
                      iconColor: AppTheme.neonMint,
                      title: "Analyzing Faces...",
                      details: "Scanning facial landmarks & biometrics",
                      isInProgress: true,
                    ),
                    const SizedBox(height: 12),

                    _buildStepItem(
                      icon: Icons.more_horiz_rounded,
                      iconColor: AppTheme.inconclusiveGray,
                      title: "Processing Audio...",
                      details: "Awaiting frame alignment",
                      isPending: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // End-to-end encrypted analysis banner card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppTheme.neonMint, size: 20),
                    SizedBox(width: 12),
                    Text(
                      "End-to-end encrypted analysis.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Row (Cancel & Boost)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _progress = 1.0;
                        });
                        widget.onScanCompleted();
                      },
                      icon: const Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 18),
                      label: const Text(
                        "Boost",
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
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String details,
    bool isCompleted = false,
    bool isInProgress = false,
    bool isPending = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInProgress ? const Color(0xFF142232) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isInProgress
            ? Border(left: BorderSide(color: AppTheme.neonMint, width: 3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: isInProgress ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    color: isCompleted ? AppTheme.neonMint : AppTheme.inconclusiveGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
