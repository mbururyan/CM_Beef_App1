import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    // Wipe the whole navigation stack so Back can't return here.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Beef Field Data',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2.4));
          }

          final data = snapshot.data?.data();
          final name = data?['full_name'] as String? ?? 'Evaluator';
          final role = data?['role'] as String? ?? 'evaluator';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $name',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(role,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.greenLight)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Farm registry and evaluations arrive in the next module.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}