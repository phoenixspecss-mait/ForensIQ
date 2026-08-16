import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expert_ai/views/register_login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeSlider extends StatefulWidget {
  const WelcomeSlider({super.key});

  @override
  State<WelcomeSlider> createState() => _WelcomeSliderState();
}

class _WelcomeSliderState extends State<WelcomeSlider>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Dark Theme Design Tokens matching reference screenshots
  static const Color bgDark = Color(0xFF0B120F);
  static const Color mintGreen = Color(0xFF50F89A);
  static const Color cardDark = Color(0xFF131E1A);
  static const Color cardBorder = Color(0xFF1F312A);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color darkButtonText = Color(0xFF081410);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animController.reset();
    _animController.forward();
    HapticFeedback.selectionClick();
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _previous() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegisterLoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return _buildDesktopSliderView();
    }

    // Mobile View (< 900px)
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _goToLogin,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main PageView Content
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPage(
                    visual: _buildSlide1Visual(),
                    title: "The world's experts, in one assistant.",
                    subtitle:
                        "Ask anything and let our network of specialist AI agents find the answer for you.",
                  ),
                  _buildPage(
                    visual: _buildSlide2Visual(),
                    title: "Invisible Coordination.",
                    subtitle:
                        "We find the best specialist for your query and handle the micro-payment instantly behind the scenes.",
                  ),
                  _buildPage(
                    visual: _buildSlide3Visual(),
                    title: "Verified, Precise, Fast.",
                    subtitle:
                        "Get started with a small wallet balance and only pay for what you use.",
                  ),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? mintGreen : const Color(0xFF273B33),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mintGreen,
                        foregroundColor: darkButtonText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkButtonText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: darkButtonText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // DESKTOP ONBOARDING SLIDER VIEW (Matching Images 1, 2, and 3)
  // =========================================================================
  Widget _buildDesktopSliderView() {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Desktop Top Navigation Header
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  // App Brand Logo (Image 2)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: mintGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: mintGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "AskExpert",
                        style: GoogleFonts.inter(
                          color: textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Top Right Page Indicator Line (Image 2)
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 28 : 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive ? mintGreen : const Color(0xFF273B33),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Desktop Main PageView Content
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: [
                  _buildDesktopSlide1(),
                  _buildDesktopSlide2(),
                  _buildDesktopSlide3(),
                ],
              ),
            ),

            // Desktop Bottom Navigation Bar (For Slide 2 & 3 back/next navigation - Image 2)
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    TextButton.icon(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back_rounded, color: textGrey, size: 18),
                      label: Text(
                        "Back",
                        style: GoogleFonts.inter(color: textGrey, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),

                    // Next Button (Mint Green Pill)
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mintGreen,
                        foregroundColor: darkButtonText,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: darkButtonText),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: darkButtonText, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Desktop Slide 1 (Image 1: Computer Frame + Headline + NEXT / SKIP) ---
  Widget _buildDesktopSlide1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Computer Monitor Visual Frame (Image 1)
          Container(
            constraints: const BoxConstraints(maxWidth: 680),
            height: 380,
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Desktop Screen Layout Graphic Preview inside monitor frame
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF0F1916),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header mock bar
                          Row(
                            children: [
                              Container(width: 20, height: 20, decoration: BoxDecoration(color: mintGreen, borderRadius: BorderRadius.circular(5))),
                              const SizedBox(width: 8),
                              Text("Welcome to AskExpert", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162520),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: mintGreen.withValues(alpha: 0.3)),
                                  ),
                                  child: Center(
                                    child: Text("Start a New Consultation\nDefine your project goals", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162520),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF233830)),
                                  ),
                                  child: Center(
                                    child: Text("Browse Expert Directory\nSearch thousands of verified specialists", textAlign: TextAlign.center, style: GoogleFonts.inter(color: textGrey, fontSize: 11)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text("Recommended Experts for You", style: GoogleFonts.inter(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            children: ["Sarah K.\nFintech Strategist", "David L.\nAI Research Lead", "Maria P.\nProduct Manager", "Robert B.\nLegal Counsel"].map((name) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131D1A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF20322B)),
                                  ),
                                  child: Text(name, style: GoogleFonts.inter(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Main Title with mint green highlight (Image 1)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: textWhite,
                height: 1.15,
                letterSpacing: -1.0,
              ),
              children: [
                const TextSpan(text: "The world's experts, in one\n"),
                TextSpan(
                  text: "assistant.",
                  style: GoogleFonts.inter(color: mintGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              "Ask anything and let our network of specialist AI agents find the answer for you.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: textGrey,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // NEXT Button (Mint Green Pill - Image 1)
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: mintGreen,
              foregroundColor: darkButtonText,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("NEXT", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: darkButtonText, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: darkButtonText, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SKIP text button
          TextButton(
            onPressed: _goToLogin,
            child: Text(
              "SKIP",
              style: GoogleFonts.inter(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 20),

          // Page Indicator Dots (Image 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 24, height: 4, decoration: BoxDecoration(color: mintGreen, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Container(width: 6, height: 4, decoration: BoxDecoration(color: const Color(0xFF273B33), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Container(width: 6, height: 4, decoration: BoxDecoration(color: const Color(0xFF273B33), borderRadius: BorderRadius.circular(2))),
            ],
          ),
        ],
      ),
    );
  }

  // --- Desktop Slide 2 (Image 2: Invisible Coordination + 3 Connected Step Cards) ---
  Widget _buildDesktopSlide2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Title (Image 2)
          Text(
            "Invisible Coordination.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: textWhite,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              "We find the best specialist for your query and handle the micro-payment instantly behind the scenes.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: textGrey,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 54),

          // 3 Connected Horizontal Process Cards (Image 2)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Step 1: Searching
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1A17),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: mintGreen, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: mintGreen.withValues(alpha: 0.3),
                              blurRadius: 16,
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.center_focus_strong_rounded, color: mintGreen, size: 32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          children: [
                            Text("Searching", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("Scanning specialized networks", textAlign: TextAlign.center, style: GoogleFonts.inter(color: textGrey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Connecting Horizontal Line 1
                Container(width: 40, height: 2, color: const Color(0xFF233A31)),

                // Step 2: Comparing
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131F1C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF233A31), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.balance_rounded, color: textGrey, size: 30),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          children: [
                            Text("Comparing", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("Evaluating expertise & cost", textAlign: TextAlign.center, style: GoogleFonts.inter(color: textGrey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Connecting Horizontal Line 2
                Container(width: 40, height: 2, color: const Color(0xFF233A31)),

                // Step 3: Paying
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131F1C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF233A31), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.payments_outlined, color: textGrey, size: 30),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          children: [
                            Text("Paying", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("Frictionless micro-transaction", textAlign: TextAlign.center, style: GoogleFonts.inter(color: textGrey, fontSize: 12)),
                          ],
                        ),
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

  // --- Desktop Slide 3 (Image 3: Verified, Precise, Fast + Central Balance Preview Card + Get Started Button) ---
  Widget _buildDesktopSlide3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),

          // Title (Image 3)
          Text(
            "Verified, Precise, Fast.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: textWhite,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              "Get started with a small wallet balance and only pay for what you use.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: textGrey,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Central Balance Preview Card (Image 3)
          Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: mintGreen.withValues(alpha: 0.1),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // SECURE badge (Image 3)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF142E25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1F4A3B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined, size: 14, color: mintGreen),
                          const SizedBox(width: 6),
                          Text(
                            "SECURE",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: mintGreen, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),

                    // ACTIVE indicator (Image 3)
                    Row(
                      children: [
                        const CircleAvatar(radius: 3.5, backgroundColor: mintGreen),
                        const SizedBox(width: 6),
                        Text(
                          "ACTIVE",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textGrey, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text("Available Balance", style: GoogleFonts.inter(color: textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
                    children: const [
                      TextSpan(text: "\$4.82 "),
                      TextSpan(text: "USD", style: TextStyle(fontSize: 18, color: textGrey, fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Big "Get Started" Button (Image 3)
          SizedBox(
            width: 420,
            height: 54,
            child: ElevatedButton(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: mintGreen,
                foregroundColor: darkButtonText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Get Started", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: darkButtonText)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: darkButtonText, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // End-to-end encrypted footer note (Image 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: textGrey, size: 12),
              const SizedBox(width: 6),
              Text("End-to-end encrypted", style: GoogleFonts.inter(color: textGrey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // Mobile Helper Pages & Widgets
  Widget _buildPage({
    required Widget visual,
    required String title,
    required String subtitle,
  }) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: visual,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textWhite,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textGrey,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide1Visual() {
    return SizedBox(
      width: 280,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(280, 250),
            painter: _DashedConnectorPainter(),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: mintGreen,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: mintGreen.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.smart_toy_rounded,
                color: darkButtonText,
                size: 52,
              ),
            ),
          ),
          Positioned(top: 20, left: 20, child: _buildSatelliteCard(Icons.edit_note_rounded, textGrey)),
          Positioned(top: 20, right: 20, child: _buildSatelliteCard(Icons.medical_services_rounded, const Color(0xFFFCA5A5))),
          Positioned(bottom: 20, left: 20, child: _buildSatelliteCard(Icons.code_rounded, mintGreen)),
          Positioned(bottom: 20, right: 20, child: _buildSatelliteCard(Icons.bar_chart_rounded, textGrey)),
        ],
      ),
    );
  }

  Widget _buildSatelliteCard(IconData icon, Color iconColor) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildSlide2Visual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPipelineStep(
            icon: Icons.search_rounded,
            iconBg: const Color(0xFF192823),
            iconColor: textGrey,
            title: "Searching",
            subtitle: "Scanning specialized networks",
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 24, color: const Color(0xFF253A32)),
            ),
          ),
          _buildPipelineStep(
            icon: Icons.compare_arrows_rounded,
            iconBg: const Color(0xFF192823),
            iconColor: textGrey,
            title: "Comparing",
            subtitle: "Evaluating expertise & cost",
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 24, color: const Color(0xFF253A32)),
            ),
          ),
          _buildPipelineStep(
            icon: Icons.check_circle_rounded,
            iconBg: mintGreen,
            iconColor: darkButtonText,
            title: "Paying",
            subtitle: "Frictionless micro-transaction",
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: textWhite)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textGrey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlide3Visual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF142E25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1F4A3B), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: mintGreen),
                    const SizedBox(width: 4),
                    Text("SECURE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: mintGreen)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("AVAILABLE BALANCE", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textGrey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("\$", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: textWhite)),
              ),
              const SizedBox(width: 4),
              Text("4.82", style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: textWhite)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: mintGreen, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.check_rounded, color: darkButtonText, size: 26)),
          ),
        ],
      ),
    );
  }
}

class _DashedConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF273B33)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final offsets = [
      const Offset(46, 46),
      Offset(size.width - 46, 46),
      Offset(46, size.height - 46),
      Offset(size.width - 46, size.height - 46),
    ];

    for (final target in offsets) {
      _drawDashedLine(canvas, center, target, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4;
    const double dashSpace = 4;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = (dx * dx + dy * dy);
    final double count = distance / (dashWidth + dashSpace);

    double x = p1.dx;
    double y = p1.dy;

    for (int i = 0; i < count; i++) {
      final double endX = x + (dx / count) * (dashWidth / (dashWidth + dashSpace));
      final double endY = y + (dy / count) * (dashWidth / (dashWidth + dashSpace));
      canvas.drawLine(Offset(x, y), Offset(endX, endY), paint);
      x += (dx / count);
      y += (dy / count);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}