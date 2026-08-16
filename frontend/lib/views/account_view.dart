import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/theme/app_theme.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  double _sensitivity = 85.0;
  bool _deepfakeModelEnabled = true;
  bool _metadataScrutinyEnabled = true;
  bool _twoFactorEnabled = true;
  bool _alertNotificationsEnabled = true;

  final TextEditingController _nameController = TextEditingController(text: "Dr. Aris Vance");
  final TextEditingController _emailController = TextEditingController(text: "a.vance@forensiq.lab");

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Platform settings saved successfully!"),
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
          // Header (Image 5 Mockup)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Platform Settings",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Configure forensic analysis thresholds, security protocols, and account details.",
                style: GoogleFonts.inter(
                  color: AppTheme.inconclusiveGray,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main 2-Column Layout (Engine & Identity Left, Quotas & Infrastructure Right)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              return isNarrow
                  ? Column(
                      children: [
                        _buildForensicEngineConfigCard(),
                        const SizedBox(height: 24),
                        _buildIdentityAndAccessCard(),
                        const SizedBox(height: 24),
                        _buildLicensingAndQuotasCard(),
                        const SizedBox(height: 24),
                        _buildInfrastructureStatusCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildForensicEngineConfigCard(),
                              const SizedBox(height: 24),
                              _buildIdentityAndAccessCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildLicensingAndQuotasCard(),
                              const SizedBox(height: 24),
                              _buildInfrastructureStatusCard(),
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

  // Left Column Card 1: Forensic Engine Configuration (Image 5 Mockup)
  Widget _buildForensicEngineConfigCard() {
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
              const Icon(Icons.tune_rounded, color: AppTheme.neonMint, size: 20),
              const SizedBox(width: 10),
              Text("Forensic Engine Configuration", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Anomaly Sensitivity Threshold", style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      "Adjust the baseline required for the AI to flag potential media manipulation. Higher sensitivity may increase false positives.",
                      style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text("High (85%)", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Slider bounds (PERMISSIVE ... BALANCED ... AGGRESSIVE)
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.neonMint,
              inactiveTrackColor: const Color(0xFF162520),
              thumbColor: AppTheme.neonMint,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _sensitivity,
              min: 0,
              max: 100,
              onChanged: (v) => setState(() => _sensitivity = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("PERMISSIVE", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("BALANCED", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("AGGRESSIVE", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2 Checkbox Cards
          Row(
            children: [
              Expanded(
                child: _buildCheckboxTile(
                  title: "Deepfake Detection Model v4.2",
                  subtitle: "Enable latest spatial-temporal consistency checks.",
                  value: _deepfakeModelEnabled,
                  onChanged: (val) => setState(() => _deepfakeModelEnabled = val ?? true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCheckboxTile(
                  title: "Metadata Scrutiny Level",
                  subtitle: "Perform deep EXIF/IPTC anomalous byte analysis.",
                  value: _metadataScrutinyEnabled,
                  onChanged: (val) => setState(() => _metadataScrutinyEnabled = val ?? true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          Checkbox(
            value: value,
            activeColor: AppTheme.neonMint,
            checkColor: Colors.black,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Left Column Card 2: Identity & Access (Image 5 Mockup)
  Widget _buildIdentityAndAccessCard() {
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
              const Icon(Icons.shield_outlined, color: AppTheme.neonMint, size: 20),
              const SizedBox(width: 10),
              Text("Identity & Access", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Full Name", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildTextField(_nameController),
                    const SizedBox(height: 16),

                    Text("Primary Email", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildTextField(_emailController),
                    const SizedBox(height: 6),
                    Text("Contact admin to modify designated institutional email.", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 10)),
                    const SizedBox(height: 16),

                    Text("Role / Department", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildBadgePill("Lead Analyst"),
                        const SizedBox(width: 8),
                        _buildBadgePill("SysAdmin"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A17),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Security Protocols", style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Two-Factor Authentication", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              Text("Currently active (YubiKey)", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 10)),
                            ],
                          ),
                          Switch(
                            value: _twoFactorEnabled,
                            activeThumbColor: AppTheme.neonMint,
                            activeTrackColor: AppTheme.neonMint.withValues(alpha: 0.3),
                            onChanged: (v) => setState(() => _twoFactorEnabled = v),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.cardBorder, height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Alert Notifications", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              Text("Email on High-Risk Detections", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 10)),
                            ],
                          ),
                          Switch(
                            value: _alertNotificationsEnabled,
                            activeThumbColor: AppTheme.neonMint,
                            activeTrackColor: AppTheme.neonMint.withValues(alpha: 0.3),
                            onChanged: (v) => setState(() => _alertNotificationsEnabled = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Footer Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: const BorderSide(color: AppTheme.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Discard Changes", style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonMint,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text("Save Identity Configuration", style: GoogleFonts.inter(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A17),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
      ),
    );
  }

  Widget _buildBadgePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF162520), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.cardBorder)),
      child: Text(label, style: GoogleFonts.firaCode(color: Colors.white, fontSize: 11)),
    );
  }

  // Right Column Card 1: Licensing & Quotas (Image 5 Mockup)
  Widget _buildLicensingAndQuotasCard() {
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
              const Icon(Icons.subtitles_outlined, color: AppTheme.neonMint, size: 20),
              const SizedBox(width: 10),
              Text("Licensing & Quotas", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          Text("Current Tier", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text("Enterprise", style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text("Active", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // Progress 1: API Calls (Monthly)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("API Calls (Monthly)", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
              Text("142k / 500k", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: 0.28, backgroundColor: Colors.white12, color: AppTheme.neonMint, minHeight: 4),
          const SizedBox(height: 16),

          // Progress 2: Storage (Evidence Locker)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Storage (Evidence Locker)", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
              Text("4.2 TB / 10 TB", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: 0.42, backgroundColor: Colors.white12, color: AppTheme.neonMint, minHeight: 4),
          const SizedBox(height: 24),

          // Button: Request Limit Increase
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.north_east_rounded, color: AppTheme.neonMint, size: 16),
              label: Text("Request Limit Increase", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.neonMint),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Right Column Card 2: Infrastructure Status (Image 5 Mockup)
  Widget _buildInfrastructureStatusCard() {
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
          Text("Infrastructure Status", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfraRow("Core Analysis Nodes", "Operational", AppTheme.neonMint),
          const SizedBox(height: 10),
          _buildInfraRow("Hash Verification DB", "Synced 2m ago", AppTheme.neonMint),
          const SizedBox(height: 10),
          _buildInfraRow("Metadata Extraction", "Degraded (High Load)", Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildInfraRow(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
        Row(
          children: [
            CircleAvatar(radius: 3, backgroundColor: color),
            const SizedBox(width: 6),
            Text(status, style: GoogleFonts.firaCode(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
