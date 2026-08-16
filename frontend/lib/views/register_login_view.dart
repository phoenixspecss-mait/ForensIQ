import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forensiq/services/auth/auth_exceptions.dart';
import 'package:forensiq/services/auth/auth_service.dart';
import 'package:forensiq/theme/app_theme.dart';
import 'package:forensiq/views/forgot_password_view.dart';

// ── MAIN AUTHENTICATION SCREEN VIEW ───────────────────────────────
class RegisterLoginView extends StatefulWidget {
  const RegisterLoginView({super.key});

  @override
  State<RegisterLoginView> createState() => _RegisterLoginViewState();
}

class _RegisterLoginViewState extends State<RegisterLoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _loading = false;
  bool _obscurePassword = true;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.firebase().signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home/', (_) => false);
      }
    } on GoogleSignInCancelledException {
      // User cancelled Google sign-in dialog - no action needed
    } catch (e) {
      debugPrint("Google Sign-In failed: $e");
      if (mounted) {
        final cleanMsg = e
            .toString()
            .replaceAll('Exception:', '')
            .replaceAll('FirebaseAuthException', '')
            .replaceAll('GenericAuthException', '')
            .trim();
        _showSnack(
          cleanMsg.isNotEmpty ? "Google Sign-In: $cleanMsg" : "Google Sign-In failed. Please try again.",
          Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSubmit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Please enter email and password", AppTheme.errorRed);
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.firebase().createUser(email: email, password: password);
      _showSnack("Registered successfully!", AppTheme.emeraldGreen);
      await AuthService.firebase().sendEmailVerification();
      _showSnack("Verification email sent!", AppTheme.emeraldGreen);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VerifyEmailView()),
        );
      }
    } on EmailAlreadyInUseException {
      try {
        await AuthService.firebase().logIn(email: email, password: password);
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          try {
            await fbUser.reload();
          } catch (_) {}
        }
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser != null && freshUser.emailVerified) {
          _showSnack("Welcome back to ForensIQ!", AppTheme.emeraldGreen);
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/home/', (_) => false);
          }
        } else {
          _showSnack("Please verify your email to continue.", AppTheme.warningOrange);
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VerifyEmailView()),
            );
          }
        }
      } on WrongPassAuthException {
        _showSnack("Incorrect password. Please try again.", Colors.redAccent);
      } on UserNotFoundException {
        _showSnack("No account found with this email.", Colors.redAccent);
      } catch (e) {
        _showSnack("Login failed: ${e.toString()}", Colors.redAccent);
      }
    } on InvalidEmailException {
      _showSnack("Please enter a valid email.", Colors.redAccent);
    } catch (_) {
      _showSnack("Something went wrong. Try again.", AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) {
      return _buildDesktopAuthLayout();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // ForensIQ Logo Container
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131E1B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emeraldGreen.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    color: AppTheme.emeraldGreen,
                    size: 44,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // App Name: ForensIQ
              Center(
                child: Text(
                  'ForensIQ',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tagline
              Center(
                child: Text(
                  "VERIFIED AGENTS • MICRO-PAYMENT MARKETPLACE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Custom Input 1: EMAIL ADDRESS
              _buildCustomInputField(
                label: "EMAIL ADDRESS",
                hintText: "e.g. alex@example.com",
                controller: _email,
                focusNode: _emailFocus,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Custom Input 2: PASSWORD
              _buildCustomInputField(
                label: "PASSWORD",
                hintText: "Enter your password",
                controller: _password,
                focusNode: _passwordFocus,
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),

              const SizedBox(height: 8),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.inter(
                      color: AppTheme.emeraldGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Submit / Login Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _handleSubmit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          "Continue",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // Divider with "OR"
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFF23322E))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR",
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFF23322E))),
                ],
              ),

              const SizedBox(height: 20),

              // Google Sign-In Button Only
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF111C19),
                    side: const BorderSide(color: Color(0xFF22342E), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _loading ? null : _signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata_rounded, color: AppTheme.emeraldGreen, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        "Continue with Google",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Scratch-Designed Premium Custom Input Field Component ---
  Widget _buildCustomInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final hasFocus = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upper Small Label
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: hasFocus ? AppTheme.emeraldGreen : const Color(0xFF8E9BAE),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),

        // Input Card Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF111C19),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFocus ? AppTheme.emeraldGreen : const Color(0xFF22342E),
              width: hasFocus ? 1.5 : 1.0,
            ),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon Square Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasFocus ? AppTheme.emeraldGreen.withValues(alpha: 0.15) : const Color(0xFF1A2B26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: hasFocus ? AppTheme.emeraldGreen : const Color(0xFF8E9BAE),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Actual TextField
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: isPassword ? obscureText : false,
                  keyboardType: keyboardType,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF5A6A7E),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // Suffix Password Eye Toggle
              if (isPassword && onToggleVisibility != null)
                IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF8E9BAE),
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopAuthLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A110F),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Navbar (Image 5)
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF192A25), width: 1)),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hub_rounded, color: AppTheme.emeraldGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "ForensIQ",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: ["Marketplace", "Agents", "Developers", "Documentation"].map((link) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          link,
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),

            // Centered Auth Box (Image 5)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: 440,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF23322E), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D2A27),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.hub_rounded, color: AppTheme.emeraldGreen, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "ForensIQ",
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "VERIFIED AGENTS • MICRO-PAYMENT MARKETPLACE",
                          style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 28),

                        _buildCustomInputField(
                          label: "EMAIL ADDRESS",
                          hintText: "e.g. alex@example.com",
                          controller: _email,
                          focusNode: _emailFocus,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildCustomInputField(
                          label: "PASSWORD",
                          hintText: "Enter your password",
                          controller: _password,
                          focusNode: _passwordFocus,
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
                              );
                            },
                            child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emeraldGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: const [
                            Expanded(child: Divider(color: Color(0xFF23322E))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text("OR", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(child: Divider(color: Color(0xFF23322E))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 24),
                            label: const Text("Continue with Google", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF23322E)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () {},
                          child: const Text("Don't have an account? Sign up", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer (Image 5)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF192A25), width: 1)),
              ),
              child: Row(
                children: [
                  const Text("© 2026 ForensIQ. All rights reserved. Verified Agents & Micro-payment Marketplace.", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  const Spacer(),
                  Wrap(
                    spacing: 20,
                    children: ["Privacy Policy", "Terms of Service", "Security", "Status", "Contact Support"].map((f) {
                      return Text(f, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12));
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── VERIFY EMAIL VIEW ─────────────────────────────────────────────
class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> with WidgetsBindingObserver {
  bool _isSending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatusSilently();
    // Fast 1-second auto-sync polling
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkStatusSilently();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-sync immediately when returning from email client
      _checkStatusSilently();
    }
  }

  Future<void> _checkStatusSilently() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
      } catch (_) {}
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh != null && fresh.emailVerified && mounted) {
        _timer?.cancel();
        Navigator.of(context).pushNamedAndRemoveUntil('/home/', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text("Verify Email", style: GoogleFonts.playfairDisplay()),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_rounded, color: AppTheme.emeraldGreen, size: 72),
            const SizedBox(height: 24),
            Text(
              "Email Verification Required",
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              "We've sent a verification email to your address. Please click the link inside to activate your ForensIQ account.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
            ),
            const SizedBox(height: 32),
            // Automatic Live Sync Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131E1B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF23322E), width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.emeraldGreen,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Auto-syncing status...",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Click the link in your email; we'll automatically direct you to the app.",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Re-send Email Primary Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSending
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSending = true);
                        try {
                          await AuthService.firebase().sendEmailVerification();
                        } catch (_) {}
                        if (!mounted) return;
                        setState(() => _isSending = false);
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Verification email re-sent!")),
                        );
                      },
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text("Re-send Email", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                _timer?.cancel();
                final nav = Navigator.of(context);
                await AuthService.firebase().logout();
                if (!mounted) return;
                nav.pushNamedAndRemoveUntil('/login', (_) => false);
              },
              child: Text("Back to Login", style: GoogleFonts.inter(color: AppTheme.emeraldGreen)),
            ),
          ],
        ),
      ),
    );
  }
}
