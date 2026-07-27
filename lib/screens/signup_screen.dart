import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  int _strength = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() => _submitting = true);

  String? error;
  try {
    await AuthService.instance.signUp(
      fullName: _nameCtrl.text,
      username: _usernameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
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

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Account created — you can now log in'),
      backgroundColor: AppColors.green,
    ),
  );
  Navigator.of(context).pop(); // back to login
}

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );

  Color _barColor(int barIndex) {
    if (_strength <= barIndex) return AppColors.inputBorder;
    if (_strength == 1) return AppColors.orange;
    if (_strength == 2) return AppColors.greenLight;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create account',
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'For FCL extension officers',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),

                    _fieldLabel('Full name'),
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Kepha Ojiambo'),
                      validator: (v) => Validators.required(v, 'Full name'),
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Username'),
                    TextFormField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          hintText: 'Lowercase, e.g. kepha.o'),
                      validator: Validators.username,
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Email'),
                    TextFormField(
                      controller: _emailCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          hintText: 'name@example.com'),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Phone'),
                    TextFormField(
                      controller: _phoneCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          hintText: '07xxxxxxxx or 01xxxxxxxx or +254...'),
                      validator: Validators.kenyanPhone,
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Password'),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (v) => setState(
                          () => _strength = Validators.passwordStrength(v)),
                      decoration: InputDecoration(
                        hintText: 'At least 8 characters with a number',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(3, (i) {
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: _barColor(i),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Confirm password'),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      // Spec: match-check runs live while typing, so this
                      // field validates per keystroke while the rest of the
                      // form stays on-blur.
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        hintText: 'Repeat your password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) => Validators.confirmPassword(
                          v, _passwordCtrl.text),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already registered?',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Log in',
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