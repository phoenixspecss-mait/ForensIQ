import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forensiq/services/api_service.dart';
import 'package:forensiq/theme/app_theme.dart';
import 'package:forensiq/views/account_view.dart';
import 'package:forensiq/views/api_view.dart';
import 'package:forensiq/views/dashboard_view.dart';
import 'package:forensiq/views/deepscan_progress_view.dart';
import 'package:forensiq/views/history_view.dart';
import 'package:forensiq/views/scan_report_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentTabIndex = 0; // 0: Dashboard, 1: Scan Results, 2: History, 3: API, 4: Settings
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
    setState(() {
      _activeJobId = jobId;
      _currentTabIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 850;

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
              },
              onCancel: () {
                setState(() => _isScanningActive = false);
              },
            )
          : ScanReportView(
              jobId: _activeJobId,
              onClose: () => setState(() => _currentTabIndex = 0),
            ),
      HistoryView(
        onViewScanDetails: _openScanDetails,
      ),
      const ApiView(),
      const AccountView(),
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Row(
          children: [
            // Left Navigation Sidebar (Screen 1, 2, 3, 4 Mockups)
            _buildSidebar(),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Responsive Top Navigation Bar
                  _buildTopHeader(),

                  // Active Screen View
                  Expanded(
                    child: pages[_currentTabIndex],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Navigation Shell (< 850px)
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildTopHeader(),
      ),
      body: pages[_currentTabIndex],
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMobileNavItem(0, Icons.dashboard_outlined, "Dashboard"),
            _buildMobileNavItem(1, Icons.assessment_outlined, "Results"),
            _buildMobileNavItem(2, Icons.history_rounded, "History"),
            _buildMobileNavItem(3, Icons.code_rounded, "API"),
            _buildMobileNavItem(4, Icons.settings_outlined, "Settings"),
          ],
        ),
      ),
    );
  }

  // Left Sidebar Component (Matching Reference Image Layout)
  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(right: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // ForensIQ Brand Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neonMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: AppTheme.neonMint, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  "ForensIQ",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Sidebar Menu Items
          _buildSidebarNavItem(0, Icons.dashboard_outlined, "Dashboard"),
          _buildSidebarNavItem(1, Icons.assessment_outlined, "SCAN RESULTS"),
          _buildSidebarNavItem(2, Icons.history_rounded, "History"),
          _buildSidebarNavItem(3, Icons.code_rounded, "</> API"),
          _buildSidebarNavItem(4, Icons.settings_outlined, "Settings"),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, IconData icon, String title) {
    final isSelected = _currentTabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentTabIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF142E25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: AppTheme.neonMint.withValues(alpha: 0.3)) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.neonMint : AppTheme.inconclusiveGray,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isSelected ? AppTheme.neonMint : AppTheme.inconclusiveGray,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Top Header Bar Component (Matching Reference Image Layout)
  Widget _buildTopHeader() {
    final titles = ["Dashboard", "Scan Results", "History", "Settings", "API"];
    final currentTitle = titles[_currentTabIndex < titles.length ? _currentTabIndex : 0];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            currentTitle,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Action Buttons (Bell + PROFILE / SAVE CHANGES / DOCUMENTATION)
          Row(
            children: [
              if (_currentTabIndex == 3) // API screen
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonMint,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    "DOCUMENTATION",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                  ),
                ),

              if (_currentTabIndex == 4) // Settings screen
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonMint,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    "SAVE CHANGES",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                  ),
                ),

              const SizedBox(width: 12),

              // Bell Notification Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Icon(Icons.notifications_outlined, color: AppTheme.inconclusiveGray, size: 18),
              ),
              const SizedBox(width: 12),

              // PROFILE Cyan Button
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentTabIndex = 4),
                icon: const Icon(Icons.person_outline_rounded, color: Colors.black, size: 16),
                label: Text(
                  "PROFILE",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonMint,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.neonMint : AppTheme.inconclusiveGray,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? AppTheme.neonMint : AppTheme.inconclusiveGray,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}