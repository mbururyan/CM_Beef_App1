import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
//import '../screens/tabs/home_tab.dart';
import '../screens/main_shell.dart';

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

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainShell()),
    (route) => false,
  );
}

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              // Keeps the form phone-width even on Chrome.
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                // Fields validate when focus leaves them (spec: on blur,
                // not per keystroke).
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header ---
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.greenDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'CM Beef App',
                        style: TextStyle(
                          color: AppColors.greenLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Beef Field App — Choice Meats Ltd.",
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
                          const InputDecoration(hintText: 'e.g. jkamau'),
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
                          // TODO(increment-4): Firebase password reset email.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Password reset arrives with Firebase wiring')),
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
                          onPressed: () {
                            // TODO(increment-3): navigate to SignupScreen.
                            Navigator.of(context).push(
                                 MaterialPageRoute(builder: (_) => const SignupScreen()));
                          },
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