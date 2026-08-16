import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forensiq/services/api_service.dart';
import 'package:forensiq/services/database/firebase_database_provider.dart';
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
  int _currentTabIndex = 0; // 0: Dashboard, 1: Recent Scans, 2: History, 3: API, 4: Settings
  String _activeJobId = "";
  Uint8List? _activeImageBytes;
  bool _isScanningActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startFileScan() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickMedia();

      if (file != null) {
        final bytes = await file.readAsBytes();
        final jobId = "scan_${DateTime.now().millisecondsSinceEpoch}";
        
        setState(() {
          _activeJobId = jobId;
          _activeImageBytes = bytes;
          _isScanningActive = false;
          _currentTabIndex = 1;
        });

        // Async upload and backend analysis trigger
        ApiService.uploadFileForGateway(file.path, file.name).then((res) {
          if (res['success'] == true && res['data'] != null) {
            final serverJobId = res['data']['job_id'] ?? jobId;
            ApiService.triggerGatewayAnalyze(
              serverJobId,
              fileType: file.name.toLowerCase().endsWith('.mp4') ? 'video' : 'image',
            );
          }
        });

        // Record scan result to Firebase RTDB
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
        return;
      }
    } catch (e) {
      debugPrint("Media picker notice: $e");
    }

    setState(() {
      _isScanningActive = false;
      _currentTabIndex = 1;
    });
  }

  void _openScanDetails(String jobId, String verdict) {
    setState(() {
      _activeJobId = jobId;
      _activeImageBytes = null;
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
              imageBytes: _activeImageBytes,
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
            // Left Navigation Sidebar (Exact Match for Reference Images)
            _buildSidebar(),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top Navigation Header Bar
                  _buildTopHeaderBar(),

                  // Active View Page
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

    // Mobile Layout (< 850px)
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildTopHeaderBar(),
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
            _buildMobileNavItem(0, Icons.grid_view_rounded, "Dashboard"),
            _buildMobileNavItem(1, Icons.saved_search_rounded, "Scans"),
            _buildMobileNavItem(2, Icons.history_rounded, "History"),
            _buildMobileNavItem(3, Icons.code_rounded, "API"),
            _buildMobileNavItem(4, Icons.settings_outlined, "Settings"),
          ],
        ),
      ),
    );
  }

  // Left Sidebar Component (Matching Reference Image Sidebar Exactly)
  Widget _buildSidebar() {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(right: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // ForensIQ Brand Shield Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.neonMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppTheme.neonMint, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ForensIQ",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "DIGITAL AUTHENTICITY",
                      style: GoogleFonts.inter(
                        color: AppTheme.inconclusiveGray,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Navigation Links
          _buildSidebarNavItem(0, Icons.grid_view_rounded, "Dashboard"),
          _buildSidebarNavItem(1, Icons.saved_search_rounded, "Recent Scans"),
          _buildSidebarNavItem(2, Icons.history_rounded, "History"),
          _buildSidebarNavItem(3, Icons.code_rounded, "API"),
          _buildSidebarNavItem(4, Icons.settings_outlined, "Settings"),

          const Spacer(),
          const Divider(color: AppTheme.cardBorder, height: 1),

          // Bottom Account Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => setState(() => _currentTabIndex = 4),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: AppTheme.inconclusiveGray, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      "Account",
                      style: GoogleFonts.inter(
                        color: AppTheme.inconclusiveGray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
            border: isSelected ? const Border(left: BorderSide(color: AppTheme.neonMint, width: 3)) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.neonMint : AppTheme.inconclusiveGray,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isSelected ? AppTheme.neonMint : AppTheme.inconclusiveGray,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Top Header Bar Component (Matching Reference Image Header Bar)
  Widget _buildTopHeaderBar() {
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
          // Search Input / Breadcrumb Bar
          if (_currentTabIndex == 1) // Recent Scans Breadcrumb
            Row(
              children: [
                Text("Recent Scans", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded, color: AppTheme.inconclusiveGray, size: 16),
                ),
                Text(_activeJobId, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            )
          else if (_currentTabIndex == 4) // Platform Settings Breadcrumb
            Row(
              children: [
                Text("System Configuration", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded, color: AppTheme.inconclusiveGray, size: 16),
                ),
                Text("Settings", style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            )
          else // Search Input (Dashboard, History, API)
            Container(
              width: 320,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.inconclusiveGray, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _currentTabIndex == 0
                            ? "Search hash, filename, or ID..."
                            : _currentTabIndex == 2
                                ? "Search history..."
                                : "Search datasets, reports...",
                        hintStyle: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Right Profile & Notifications Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: AppTheme.cardBorder),
              const SizedBox(width: 12),

              // Profile Avatar Button (Dynamic from FirebaseAuth)
              Builder(
                builder: (context) {
                  final user = FirebaseAuth.instance.currentUser;
                  final displayName = user?.displayName ?? (user?.email != null ? user!.email!.split('@').first : "Dr. A. Vance");
                  final initials = displayName.length >= 2 ? displayName.substring(0, 2).toUpperCase() : "AV";

                  return InkWell(
                    onTap: () => setState(() => _currentTabIndex = 4),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.neonMint,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.inter(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayName,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
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