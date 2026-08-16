import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';
import 'package:expert_ai/views/account_view.dart';
import 'package:expert_ai/views/certificate_view.dart';
import 'package:expert_ai/views/dashboard_view.dart';
import 'package:expert_ai/views/deepscan_progress_view.dart';
import 'package:expert_ai/views/history_view.dart';
import 'package:expert_ai/views/scan_report_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentTabIndex = 0; // 0: Home, 1: Scan, 2: History, 3: Profile
  String _activeJobId = "scan_001";
  bool _isScanningActive = false;

  void _startFileScan() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickMedia();

      if (file != null) {
        final res = await ApiService.uploadFileForGateway(file.path, file.name);
        if (res['success'] == true && res['data'] != null) {
          _activeJobId = res['data']['job_id'] ?? "job_${DateTime.now().millisecondsSinceEpoch}";
        }
      }
    } catch (e) {
      debugPrint("Media picker notice: $e");
    }

    setState(() {
      _isScanningActive = true;
      _currentTabIndex = 1;
    });
  }

  void _openScanDetails(String jobId, String verdict) {
    if (verdict == 'MANIPULATED') {
      _showReportModal(jobId);
    } else {
      _showCertificateModal(jobId);
    }
  }

  void _showReportModal(String jobId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ScanReportView(
          jobId: jobId,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showCertificateModal(String jobId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: CertificateView(
          jobId: jobId,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardView(
        onStartScanPressed: _startFileScan,
        onViewScanDetails: _openScanDetails,
      ),
      _isScanningActive
          ? DeepScanProgressView(
              jobId: _activeJobId,
              onScanCompleted: () {
                setState(() => _isScanningActive = false);
                _showReportModal(_activeJobId);
              },
              onCancel: () {
                setState(() => _isScanningActive = false);
              },
            )
          : DashboardView(
              onStartScanPressed: _startFileScan,
              onViewScanDetails: _openScanDetails,
            ),
      HistoryView(
        onViewScanDetails: _openScanDetails,
      ),
      const AccountView(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: pages[_currentTabIndex],

      // Floating Center + Scan Action Button (as shown on Screen 1)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _currentTabIndex == 0
          ? GestureDetector(
              onTap: _startFileScan,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.neonMint,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonMint.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_rounded, color: Colors.black, size: 22),
                    SizedBox(width: 6),
                    Text(
                      "Scan",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,

      // Bottom Navigation Bar with Circular Highlight Icons (Screens 1 & 2)
      bottomNavigationBar: Container(
        height: 74,
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Home"),
            _buildNavItem(1, Icons.crop_free_rounded, "Scan"),
            _buildNavItem(2, Icons.history_rounded, "History"),
            _buildNavItem(3, Icons.person_outline_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;

    return InkWell(
      onTap: () {
        if (index == 1 && !_isScanningActive) {
          _startFileScan();
        } else {
          setState(() => _currentTabIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.neonMint : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : AppTheme.inconclusiveGray,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.neonMint : AppTheme.inconclusiveGray,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}