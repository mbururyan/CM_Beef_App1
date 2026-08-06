import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Held deliberately: long enough to read as branding rather than a
    // flash before the login form.
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    // A returning EO keeps their cached profile, so every write still
    // stamps the right name even with no signal.
    if (user != null) await SessionService.instance.load();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            user != null ? const MainShell() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/bull_splash.png',
              width: 108,
              height: 108,
              // The artwork is a silhouette, so a colour filter tints it
              // without needing a second copy of the file.
              color: AppColors.greenLight,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ranch Evaluator',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Choice Meats Ltd",
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}