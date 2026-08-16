import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/theme/app_theme.dart';

class ApiView extends StatefulWidget {
  const ApiView({super.key});

  @override
  State<ApiView> createState() => _ApiViewState();
}

class _ApiViewState extends State<ApiView> {
  String _apiKey = "fiq_live_98a72b14c30d4e5f6g7h8i9j01a2b";
  bool _isCopied = false;

  void _copyKey() {
    Clipboard.setData(ClipboardData(text: _apiKey));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("API Key copied to clipboard!"),
        backgroundColor: AppTheme.neonMint,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _regenerateKey() {
    setState(() {
      _apiKey = "fiq_live_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}1a2b";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("New API key generated successfully!"),
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
          // 1. API Key Management Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "API Key Management",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "API Key",
                  style: GoogleFonts.inter(
                    color: AppTheme.inconclusiveGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return isNarrow
                        ? Column(
                            children: [
                              _buildKeyTextField(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildCopyBtn()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildRegenerateBtn()),
                                ],
                              )
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildKeyTextField()),
                              const SizedBox(width: 12),
                              _buildCopyBtn(),
                              const SizedBox(width: 8),
                              _buildRegenerateBtn(),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Usage Statistics Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Usage Statistics",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Requests per Day",
                          style: GoogleFonts.inter(
                            color: AppTheme.inconclusiveGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Total Requests: ",
                            style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13),
                          ),
                          TextSpan(
                            text: "11.4k",
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bar Chart Visualization (Screen 4 Mockup)
                SizedBox(
                  height: 240,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBarItem("Oct 21", "1.2k", 0.52),
                      _buildBarItem("Oct 22", "1.5k", 0.65),
                      _buildBarItem("Oct 23", "0.8k", 0.35),
                      _buildBarItem("Oct 24", "1.6k", 0.70),
                      _buildBarItem("Oct 25", "2.0k", 0.85),
                      _buildBarItem("Oct 26", "1.6k", 0.70),
                      _buildBarItem("Oct 27", "2.3k", 1.00),
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

  Widget _buildKeyTextField() {
    final masked = "${_apiKey.substring(0, 8)}••••••••••••••••${_apiKey.substring(_apiKey.length - 4)}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        masked,
        style: GoogleFonts.firaCode(
          color: Colors.white,
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCopyBtn() {
    return ElevatedButton(
      onPressed: _copyKey,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF192A24),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        _isCopied ? "COPIED" : "COPY",
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildRegenerateBtn() {
    return ElevatedButton(
      onPressed: _regenerateKey,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.neonMint,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        "REGENERATE",
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
      ),
    );
  }

  Widget _buildBarItem(String label, String valueText, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF162A23),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            valueText,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 160 * heightFactor,
          decoration: BoxDecoration(
            color: AppTheme.neonMint,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.neonMint.withValues(alpha: 0.6),
                AppTheme.neonMint,
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12),
        ),
      ],
    );
  }
}
