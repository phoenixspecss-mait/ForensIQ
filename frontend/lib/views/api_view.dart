import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/services/database/firebase_database_provider.dart';
import 'package:forensiq/theme/app_theme.dart';

class ApiView extends StatefulWidget {
  const ApiView({super.key});

  @override
  State<ApiView> createState() => _ApiViewState();
}

class _ApiViewState extends State<ApiView> {
  final FirebaseDatabaseProvider _db = FirebaseDatabaseProvider();
  String _prodKey = "fiq_live_f892e947a102b3c4d5e6f7a8b9c0a9c2";
  final String _stagingKey = "fiq_test_1b44c839d01e2f3a4b5c6d7e8f93f81";

  @override
  void initState() {
    super.initState();
    _loadUserKey();
  }

  Future<void> _loadUserKey() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final key = await _db.fetchUserApiKey(user.uid);
      if (key != null && key.isNotEmpty && mounted) {
        setState(() => _prodKey = key);
      }
    }
  }

  void _createNewKey() async {
    final randHex = List.generate(24, (_) => Random().nextInt(16).toRadixString(16)).join();
    final newKey = "fiq_live_$randHex";
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.saveUserApiKey(user.uid, newKey);
    }
    if (mounted) {
      setState(() => _prodKey = newKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New Production API Key generated & saved to database!"),
          backgroundColor: AppTheme.neonMint,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyKey(String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("API Key copied to clipboard!"),
        backgroundColor: AppTheme.neonMint,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Action Buttons (Image 4 Mockup)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "API Environment",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage integration keys and monitor forensic analysis throughput.",
                    style: GoogleFonts.inter(
                      color: AppTheme.inconclusiveGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                    label: Text("Export Logs", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _createNewKey,
                    icon: const Icon(Icons.add_rounded, color: Colors.black, size: 18),
                    label: Text("+ Create New Key", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonMint,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main 2-Column Section (Authentication Keys Left, Volume & Docs Right)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              return isNarrow
                  ? Column(
                      children: [
                        _buildAuthenticationKeysCard(),
                        const SizedBox(height: 24),
                        _buildSevenDayVolumeCard(),
                        const SizedBox(height: 24),
                        _buildDeveloperResourcesCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildAuthenticationKeysCard()),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildSevenDayVolumeCard(),
                              const SizedBox(height: 24),
                              _buildDeveloperResourcesCard(),
                            ],
                          ),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // Left Column Card: Authentication Keys (Image 4 Mockup)
  Widget _buildAuthenticationKeysCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.vpn_key_outlined, color: AppTheme.neonMint, size: 20),
                  const SizedBox(width: 10),
                  Text("Authentication Keys", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF142922),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("2 Active", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Key 1: Production Environment
          _buildKeyCard(
            title: "Production Environment",
            statusColor: AppTheme.neonMint,
            createdDate: "Created on Oct 24, 2023",
            keyText: "${_prodKey.substring(0, 13)}*************************${_prodKey.substring(_prodKey.length - 4)}",
            fullKey: _prodKey,
          ),
          const SizedBox(height: 16),

          // Key 2: Staging Testing
          _buildKeyCard(
            title: "Staging Testing",
            statusColor: Colors.orangeAccent,
            createdDate: "Created on Nov 02, 2023",
            keyText: "${_stagingKey.substring(0, 13)}*************************${_stagingKey.substring(_stagingKey.length - 4)}",
            fullKey: _stagingKey,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCard({
    required String title,
    required Color statusColor,
    required String createdDate,
    required String keyText,
    required String fullKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  CircleAvatar(radius: 3, backgroundColor: statusColor),
                ],
              ),
              Text("Revoke", style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(createdDate, style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Text(
                    keyText,
                    style: GoogleFonts.firaCode(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppTheme.inconclusiveGray, size: 18),
                onPressed: () => _copyKey(fullKey),
              ),
              OutlinedButton.icon(
                onPressed: _createNewKey,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                label: Text("Roll", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: const BorderSide(color: AppTheme.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Right Column Card 1: 7-Day Volume (Image 4 Mockup)
  Widget _buildSevenDayVolumeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.neonMint, size: 20),
              const SizedBox(width: 10),
              Text("7-Day Volume", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Text("14.2k", style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.north_east_rounded, color: AppTheme.neonMint, size: 14),
              const SizedBox(width: 4),
              Text("+12% vs previous week", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),

          // Bar chart representation
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar("M", 0.5),
                _buildBar("T", 0.75),
                _buildBar("W", 0.6),
                _buildBar("T", 0.9),
                _buildBar("F", 0.7),
                _buildBar("S", 0.45),
                _buildBar("S", 0.85),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double hFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 80 * hFactor,
          decoration: BoxDecoration(color: AppTheme.neonMint, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 8),
        Text(day, style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Right Column Card 2: Developer Resources (Image 4 Mockup)
  Widget _buildDeveloperResourcesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: AppTheme.neonMint, size: 20),
              const SizedBox(width: 10),
              Text("Developer Resources", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildResourceTile(Icons.code_rounded, "API Reference", "Endpoints & payloads"),
          const SizedBox(height: 12),
          _buildResourceTile(Icons.webhook_rounded, "Webhooks", "Real-time scan alerts"),
          const SizedBox(height: 12),
          _buildResourceTile(Icons.terminal_rounded, "Client SDKs", "Python, Node.js, Go"),
        ],
      ),
    );
  }

  Widget _buildResourceTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.inconclusiveGray, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: AppTheme.inconclusiveGray, size: 16),
        ],
      ),
    );
  }
}
