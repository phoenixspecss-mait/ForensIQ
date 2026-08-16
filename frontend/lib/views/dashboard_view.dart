import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/theme/app_theme.dart';

class DashboardView extends StatefulWidget {
  final VoidCallback onStartScanPressed;
  final Function(String jobId, String type) onViewScanDetails;

  const DashboardView({
    super.key,
    required this.onStartScanPressed,
    required this.onViewScanDetails,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final List<Map<String, dynamic>> _queueItems = [
    {
      "id": "#FX-8921A",
      "source": "evidence_clip_01.mp4",
      "type": ".MP4",
      "status": "Authentic",
      "confidence": "99.8%",
      "color": AppTheme.neonMint,
    },
    {
      "id": "#FX-8921B",
      "source": "interview_audio_raw.wav",
      "type": ".WAV",
      "status": "Analyzing",
      "confidence": "--",
      "color": Colors.cyanAccent,
    },
    {
      "id": "#FX-8921C",
      "source": "suspect_photo_hd.jpg",
      "type": ".JPG",
      "status": "Manipulated",
      "confidence": "12.4%",
      "color": AppTheme.manipulatedRed,
    },
    {
      "id": "#FX-8921D",
      "source": "cctv_cam4_1024.mp4",
      "type": ".MP4",
      "status": "Unverifiable",
      "confidence": "45.1%",
      "color": Colors.orangeAccent,
    },
    {
      "id": "#FX-8921E",
      "source": "doc_scan_001.png",
      "type": ".PNG",
      "status": "Authentic",
      "confidence": "97.2%",
      "color": AppTheme.neonMint,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Action Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "System Dashboard",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Real-time media authentication metrics and processing queue.",
                    style: GoogleFonts.inter(
                      color: AppTheme.inconclusiveGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onStartScanPressed,
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                label: Text(
                  "+ New Batch Scan",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonMint,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Metrics & Dropzone Layout Row (Image 2 Mockup)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              return isNarrow
                  ? Column(
                      children: [
                        _buildMetricsCards(),
                        const SizedBox(height: 24),
                        _buildDropzoneCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 320, child: _buildMetricsCards()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildDropzoneCard()),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // 3. Queue Table & System Activity Row (Image 2 Mockup)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              return isNarrow
                  ? Column(
                      children: [
                        _buildLiveQueueTable(),
                        const SizedBox(height: 24),
                        _buildSystemActivityFeed(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildLiveQueueTable()),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildSystemActivityFeed()),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // 3 Metric Cards (Total Scans 24H, Confidence Score Avg, Anomalies Detected)
  Widget _buildMetricsCards() {
    return Column(
      children: [
        // Stat 1: Total Scans
        Container(
          padding: const EdgeInsets.all(20),
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
                  Text("TOTAL SCANS (24H)", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
                  const Icon(Icons.sync_rounded, color: AppTheme.neonMint, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text("14,289", style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.north_east_rounded, color: AppTheme.neonMint, size: 14),
                  const SizedBox(width: 4),
                  Text("+12.5% vs yesterday", style: GoogleFonts.inter(color: AppTheme.neonMint, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stat 2: Confidence Score Avg
        Container(
          padding: const EdgeInsets.all(20),
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
                  Text("CONFIDENCE SCORE AVG", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
                  const Icon(Icons.verified_user_outlined, color: AppTheme.neonMint, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text("98.4%", style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.neonMint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stat 3: Anomalies Detected
        Container(
          padding: const EdgeInsets.all(20),
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
                  Text("ANOMALIES DETECTED", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold)),
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.manipulatedRed, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text("342", style: GoogleFonts.inter(color: AppTheme.manipulatedRed, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Deepfake: 112 | Metadata: 230", style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // Drag & Drop Media Box (Image 2 Mockup)
  Widget _buildDropzoneCard() {
    return Container(
      height: 350,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonMint.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF142922),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.neonMint.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.neonMint, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            "Drag & Drop Media for Analysis",
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Supported formats: .MP4, .JPG, .PNG, .WAV. Maximum file size: 2GB.\nArchives (.ZIP) will be automatically unpacked and queued.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onStartScanPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2F28),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppTheme.cardBorder),
              ),
              elevation: 0,
            ),
            child: Text("Browse Local Files", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // Live Processing Queue Table (Image 2 Mockup)
  Widget _buildLiveQueueTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 4, backgroundColor: AppTheme.neonMint),
                    const SizedBox(width: 8),
                    Text("Live Processing Queue", style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.filter_list_rounded, color: AppTheme.inconclusiveGray, size: 18),
                    SizedBox(width: 12),
                    Icon(Icons.more_vert_rounded, color: AppTheme.inconclusiveGray, size: 18),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.cardBorder, height: 1),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildTableHeader("FILE ID")),
                Expanded(flex: 3, child: _buildTableHeader("SOURCE")),
                Expanded(flex: 1, child: _buildTableHeader("TYPE")),
                Expanded(flex: 2, child: _buildTableHeader("STATUS")),
                Expanded(flex: 2, child: _buildTableHeader("CONFIDENCE")),
              ],
            ),
          ),
          const Divider(color: AppTheme.cardBorder, height: 1),

          // Rows
          ..._queueItems.map((item) {
            return InkWell(
              onTap: () => widget.onViewScanDetails(item['id'], item['status']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF14221E), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(item['id'], style: GoogleFonts.firaCode(color: AppTheme.inconclusiveGray, fontSize: 12))),
                    Expanded(flex: 3, child: Text(item['source'], style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 1, child: Text(item['type'], style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 12))),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          if (item['status'] == 'Analyzing')
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
                          else
                            CircleAvatar(radius: 3, backgroundColor: item['color']),
                          const SizedBox(width: 6),
                          Text(item['status'], style: GoogleFonts.inter(color: item['color'], fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Text(item['confidence'], style: GoogleFonts.inter(color: item['color'], fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold),
    );
  }

  // System Activity Feed Column (Image 2 Mockup)
  Widget _buildSystemActivityFeed() {
    final activities = [
      {
        "time": "10:42 AM",
        "tag": "Automated Alert",
        "desc": "Metadata anomaly detected in batch #B-449.",
        "color": AppTheme.manipulatedRed,
      },
      {
        "time": "09:15 AM",
        "tag": "User Action",
        "desc": "Analyst J.Doe exported report for case #C-882.",
        "color": AppTheme.neonMint,
      },
      {
        "time": "08:00 AM",
        "tag": "System",
        "desc": "Daily model retraining completed successfully. Accuracy improved by 0.02%.",
        "color": AppTheme.inconclusiveGray,
      },
      {
        "time": "Yesterday, 11:30 PM",
        "tag": "System",
        "desc": "Database backup completed to secure storage tier.",
        "color": AppTheme.inconclusiveGray,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Activity", style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...activities.map((act) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 4, backgroundColor: act['color'] as Color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${act['time']} • ${act['tag']}",
                          style: GoogleFonts.inter(color: AppTheme.inconclusiveGray, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          act['desc'] as String,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
