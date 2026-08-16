import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/services/database/firebase_database_provider.dart';
import 'package:forensiq/theme/app_theme.dart';

class HistoryView extends StatefulWidget {
  final Function(String jobId, String verdict) onViewScanDetails;

  const HistoryView({super.key, required this.onViewScanDetails});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _activeFilter = "All";
  int _currentPage = 1;
  bool _isLoading = true;
  final FirebaseDatabaseProvider _db = FirebaseDatabaseProvider();

  List<Map<String, dynamic>> _allHistory = [];

  @override
  void initState() {
    super.initState();
    _loadLiveHistory();
  }

  Future<void> _loadLiveHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final realScans = await _db.fetchUserScans(user.uid);
        if (mounted && realScans.isNotEmpty) {
          final List<Map<String, dynamic>> parsed = realScans.map((s) {
            final verdict = (s['verdict'] ?? s['result'] ?? 'AUTHENTIC').toString().toUpperCase();
            final isAuthentic = verdict.contains('AUTHENTIC');
            final isManipulated = verdict.contains('MANIPULATED');
            final color = isAuthentic
                ? AppTheme.neonMint
                : (isManipulated ? AppTheme.manipulatedRed : Colors.orangeAccent);
            final filename = s['filename'] ?? s['title'] ?? s['original_filename'] ?? "Media Artifact";
            final ext = filename.contains('.') ? ".${filename.split('.').last.toUpperCase()}" : ".JPG";
            final category = ext == ".MP4" || ext == ".MOV" || ext == ".AVI"
                ? "Videos"
                : (ext == ".WAV" || ext == ".MP3" ? "Audio" : "Images");

            return {
              "id": s['id'] ?? s['job_id'] ?? "scan_${DateTime.now().millisecondsSinceEpoch}",
              "filename": filename,
              "type": ext,
              "result": isAuthentic ? "Authentic" : (isManipulated ? "Manipulated" : "Unverifiable"),
              "confidence": s['confidence'] ?? (isAuthentic ? "99.2%" : (isManipulated ? "89.4%" : "45.0%")),
              "date": s['date'] ?? s['time_display'] ?? "Today",
              "color": color,
              "category": category,
              "icon": category == "Videos"
                  ? Icons.video_camera_back_outlined
                  : (category == "Audio" ? Icons.insert_drive_file_outlined : Icons.image_outlined),
            };
          }).toList();

          setState(() {
            _allHistory = parsed;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Live history fetch notice: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _activeFilter == "All"
        ? _allHistory
        : _allHistory.where((item) => item['category'] == _activeFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Filter Pills (Image 3 Mockup)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Scan History",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Review and filter past authenticity reports.",
                    style: GoogleFonts.inter(
                      color: AppTheme.inconclusiveGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: ["All", "Images", "Videos", "Audio"].map((filter) {
                  final isActive = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      onTap: () => setState(() => _activeFilter = filter),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.neonMint : const Color(0xFF14221E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? AppTheme.neonMint : AppTheme.cardBorder),
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            color: isActive ? Colors.black : Colors.white,
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table Card (Image 3 Mockup)
          _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.neonMint)),
                )
              : Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildHeaderCell("FILE NAME")),
                      Expanded(flex: 1, child: _buildHeaderCell("TYPE")),
                      Expanded(flex: 2, child: _buildHeaderCell("RESULT")),
                      Expanded(flex: 2, child: _buildHeaderCell("CONFIDENCE")),
                      Expanded(flex: 2, child: _buildHeaderCell("DATE")),
                    ],
                  ),
                ),

                // Rows or Empty State
                filteredList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.manage_search_rounded, color: AppTheme.neonMint, size: 44),
                              const SizedBox(height: 12),
                              Text(
                                "No Scan History Found",
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Upload a media file to record your first forensic scan.",
                                style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: filteredList.map((item) {
                          return InkWell(
                    onTap: () => widget.onViewScanDetails(item['id'], item['result']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF14221E), width: 1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Icon(item['icon'] as IconData, color: AppTheme.inconclusiveGray, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['filename'],
                                    style: GoogleFonts.firaCode(color: Colors.white, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF162520), borderRadius: BorderRadius.circular(4)),
                                child: Text(item['type'], style: GoogleFonts.firaCode(color: AppTheme.inconclusiveGray, fontSize: 11)),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: item['color']),
                                const SizedBox(width: 6),
                                Text(
                                  item['result'],
                                  style: GoogleFonts.inter(color: item['color'], fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['confidence'],
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['date'],
                              style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

                // Table Footer Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Showing 1 to 4 of 24 entries", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
                      Row(
                        children: [
                          _buildPageBtn("<", false, () {
                            if (_currentPage > 1) setState(() => _currentPage--);
                          }),
                          const SizedBox(width: 6),
                          _buildPageBtn("1", _currentPage == 1, () => setState(() => _currentPage = 1)),
                          const SizedBox(width: 6),
                          _buildPageBtn("2", _currentPage == 2, () => setState(() => _currentPage = 2)),
                          const SizedBox(width: 6),
                          _buildPageBtn("3", _currentPage == 3, () => setState(() => _currentPage = 3)),
                          const SizedBox(width: 6),
                          Text("...", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray)),
                          const SizedBox(width: 6),
                          _buildPageBtn(">", false, () => setState(() => _currentPage++)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPageBtn(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppTheme.neonMint : const Color(0xFF14221E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? AppTheme.neonMint : AppTheme.cardBorder),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(color: active ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
