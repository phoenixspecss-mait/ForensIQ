import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/theme/app_theme.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  double _sensitivity = 75.0;
  bool _twoFactorEnabled = true;
  bool _emailNotificationsEnabled = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: "••••••••");

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _emailController.text = user?.email ?? "user@forensiq.com";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Settings saved successfully!"),
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
          // 1. Sensitivity Threshold Card
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
                  "Sensitivity Threshold",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Adjust the detection sensitivity",
                  style: GoogleFonts.inter(
                    color: AppTheme.inconclusiveGray,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                // Slider with Value Callout Bubble (Screen 3 Mockup)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppTheme.neonMint,
                            inactiveTrackColor: const Color(0xFF162520),
                            thumbColor: AppTheme.neonMint,
                            overlayColor: AppTheme.neonMint.withValues(alpha: 0.2),
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          ),
                          child: Slider(
                            value: _sensitivity,
                            min: 0,
                            max: 100,
                            onChanged: (val) => setState(() => _sensitivity = val),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Low", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
                              Text("High", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Callout Bubble over Thumb
                    Positioned(
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.neonMint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "${_sensitivity.toInt()}%",
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Account Management Card
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
                  "Account Management",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Email Address
                Text("Email Address", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(_emailController, isSecret: false),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF192A24),
                        foregroundColor: AppTheme.neonMint,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text("EDIT", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonMint)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Password
                Text("Password", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(_passwordController, isSecret: true),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF192A24),
                        foregroundColor: AppTheme.neonMint,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text("CHANGE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neonMint)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Two-Factor Authentication Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Two-Factor Authentication", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Switch(
                      value: _twoFactorEnabled,
                      activeThumbColor: AppTheme.neonMint,
                      activeTrackColor: AppTheme.neonMint.withValues(alpha: 0.3),
                      inactiveThumbColor: AppTheme.inconclusiveGray,
                      inactiveTrackColor: const Color(0xFF162520),
                      onChanged: (val) => setState(() => _twoFactorEnabled = val),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email Notifications Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Email Notifications", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Switch(
                      value: _emailNotificationsEnabled,
                      activeThumbColor: AppTheme.neonMint,
                      activeTrackColor: AppTheme.neonMint.withValues(alpha: 0.3),
                      inactiveThumbColor: AppTheme.inconclusiveGray,
                      inactiveTrackColor: const Color(0xFF162520),
                      onChanged: (val) => setState(() => _emailNotificationsEnabled = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.manipulatedRed, size: 20),
              label: const Text(
                "Sign Out of ForensIQ",
                style: TextStyle(
                  color: AppTheme.manipulatedRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.manipulatedRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, {required bool isSecret}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: isSecret,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }
}
