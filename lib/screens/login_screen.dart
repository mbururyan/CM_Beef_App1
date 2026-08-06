import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    String? error;
    try {
      await AuthService.instance.signIn(
        username: _usernameCtrl.text,
        password: _passwordCtrl.text,
      );
      // Cache the profile now, while there is certainly a connection —
      // every later write stamps the EO's name from this.
      await SessionService.instance.load();
    } on AuthException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong — try again';
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.orange),
      );
      return;
    }

    // Burn the bridge: back from Home should leave the app, not return
    // to a login form.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              // Keeps the form phone-width even on a wide screen.
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                // Fields validate when focus leaves them, not on every
                // keystroke.
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header: the same mark as the splash ---
                    Image.asset(
                      'assets/icons/bull_splash.png',
                      width: 72,
                      height: 72,
                      color: AppColors.greenLight,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "For CM extension officers",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 28),

                    // --- Username ---
                    _fieldLabel('Username'),
                    TextFormField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration:
                          const InputDecoration(hintText: 'e.g. kepha.o'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username cannot be blank'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Password ---
                    _fieldLabel('Password'),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password cannot be blank'
                          : null,
                    ),

                    // --- Forgot password ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO(auth): Firebase password reset email.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Ask your admin to reset your password for now')),
                          );
                        },
                        child: const Text('Forgot password?',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- Submit ---
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 14),

                    // --- Signup link ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No account?',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted)),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          ),
                          child: const Text('Sign up',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}