import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forensiq/services/auth/auth_service.dart';
import 'package:forensiq/theme/app_theme.dart';
import 'package:forensiq/views/register_login_view.dart';
import 'package:forensiq/views/app_shell.dart';
import 'package:forensiq/views/onboarding/welcome_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handling to prevent unexpected app crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error caught: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error caught: $error');
    return true; // Prevents process crash
  };

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase initializeApp error notice: $e");
  }

  // App Check platform guard (Android / iOS / Web only)
  try {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
    }
  } catch (e) {
    debugPrint("App Check initialization notice: $e");
  }

  // Check if user has seen onboarding before
  bool hasSeenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  } catch (e) {
    debugPrint("SharedPreferences notice: $e");
  }

  runApp(
    MaterialApp(
      title: 'ForensIQ',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: HomePage(hasSeenOnboarding: hasSeenOnboarding),
      routes: {
        '/login': (context) => const RegisterLoginView(),
        '/home/': (context) => const AppShell(),
        '/onboarding': (context) => const WelcomeSlider(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  final bool hasSeenOnboarding;
  const HomePage({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle stream errors gracefully
        if (snapshot.hasError) {
          debugPrint("Auth State Stream Error: ${snapshot.error}");
          return hasSeenOnboarding
              ? const RegisterLoginView()
              : const WelcomeSlider();
        }

        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
            ),
          );
        }

        // Not logged in
        if (snapshot.data == null) {
          if (!hasSeenOnboarding) {
            return const WelcomeSlider();
          }
          return const RegisterLoginView();
        }

        // Logged in — check email verification AND Phone Auth
        final user = snapshot.data!;
        final isPhoneAuth = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
        final isVerified = AuthService.firebase().currentUser?.isEmailVeified ?? user.emailVerified;

        if (isVerified || isPhoneAuth) {
          return const AppShell();
        } else {
          return const VerifyEmailView();
        }
      },
    );
  }
}