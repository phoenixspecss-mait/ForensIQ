import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/theme/app_theme.dart';

class HistoryView extends StatefulWidget {
  final Function(String jobId, String verdict) onViewScanDetails;

  const HistoryView({super.key, required this.onViewScanDetails});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  String _searchQuery = "";

  final List<Map<String, dynamic>> _allHistory = [
    {
      "id": "scan_001",
      "filename": "contract_scan.pdf",
      "type": "PDF",
      "result": "AUTHENTIC",
      "confidence": "99%",
      "date": "2023-10-27"
    },
    {
      "id": "scan_002",
      "filename": "interview_edit.mp4",
      "type": "Video",
      "result": "MANIPULATED",
      "confidence": "85%",
      "date": "2023-10-28"
    },
    {
      "id": "scan_003",
      "filename": "image_evidence.jpg",
      "type": "Image",
      "result": "AUTHENTIC",
      "confidence": "95%",
      "date": "2023-10-25"
    },
    {
      "id": "scan_004",
      "filename": "audio_statement.wav",
      "type": "Audio",
      "result": "AUTHENTIC",
      "confidence": "98%",
      "date": "2023-10-24"
    },
    {
      "id": "scan_005",
      "filename": "surveillance_clip.mov",
      "type": "Video",
      "result": "MANIPULATED",
      "confidence": "92%",
      "date": "2023-10-23"
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _allHistory.where((item) {
      final name = item['filename'].toString().toLowerCase();
      final type = item['type'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || type.contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Search & Filter Header (Screen 2 Mockup)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 240,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "SEARCH",
                          hintStyle: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12, fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const Icon(Icons.search_rounded, color: AppTheme.inconclusiveGray, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Table Card (Screen 2 Mockup)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
            ),
            child: Column(
              children: [
                // Table Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildHeaderCell("File Name ↕")),
                      Expanded(flex: 1, child: _buildHeaderCell("Type ↕")),
                      Expanded(flex: 2, child: _buildHeaderCell("Result ↕")),
                      Expanded(flex: 2, child: _buildHeaderCell("Confidence ↕")),
                      Expanded(flex: 2, child: _buildHeaderCell("Date ↕")),
                    ],
                  ),
                ),

                // Table Rows
                ...filteredList.map((item) => _buildTableRow(item)),

                // Table Pagination Bar (Screen 2 Mockup)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.inconclusiveGray, size: 20),
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162A23),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.neonMint.withValues(alpha: 0.3)),
                        ),
                        child: Text("1", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(".. 7", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.inconclusiveGray, size: 20),
                        onPressed: () => setState(() => _currentPage++),
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

  Widget _buildHeaderCell(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppTheme.inconclusiveGray,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
    final isAuthentic = item['result'] == 'AUTHENTIC';
    return InkWell(
      onTap: () => widget.onViewScanDetails(item['id'], item['result']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF15221E), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                item['filename'],
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                item['type'],
                style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAuthentic ? AppTheme.neonMint.withValues(alpha: 0.15) : AppTheme.manipulatedRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['result'],
                    style: GoogleFonts.inter(
                      color: isAuthentic ? AppTheme.neonMint : AppTheme.manipulatedRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item['confidence'],
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item['date'],
                style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
