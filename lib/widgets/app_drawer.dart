import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?', style: TextStyle(fontSize: 17)),
        content: const Text(
          'Any unsynced work stays safe on this phone.',
          style:
              TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String comingWith,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary)),
      onTap: () {
        Navigator.of(context).pop(); // close the drawer first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label arrives with $comingWith')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return Drawer(
      backgroundColor: const Color(0xFF181818),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Profile card ---
            Padding(
              padding: const EdgeInsets.all(14),
              child: FutureBuilder<
                  DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final name = data?['full_name'] as String? ?? '…';
                  final username =
                      data?['username'] as String? ?? '';
                  final role =
                      data?['role'] as String? ?? 'evaluator';
                  final initials = name
                      .split(' ')
                      .where((p) => p.isNotEmpty)
                      .take(2)
                      .map((p) => p[0].toUpperCase())
                      .join();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.greenDark,
                          child: Text(initials,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.greenLight)),
                        ),
                        const SizedBox(height: 8),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('$username · $role',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- Menu (stubs until their modules land) ---
            _item(context,
                icon: Icons.cloud_upload_outlined,
                label: 'Sync center',
                comingWith: 'the sync module'),
            _item(context,
                icon: Icons.description_outlined,
                label: 'My reports',
                comingWith: 'the PDF module'),
            _item(context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                comingWith: 'a later increment'),
            _item(context,
                icon: Icons.help_outline,
                label: 'Help & about',
                comingWith: 'a later increment'),

            const Spacer(),

            // --- Logout ---
            const Divider(
                height: 1, thickness: 0.5, color: Color(0xFF2E2E2E)),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout,
                  size: 20, color: AppColors.orange),
              title: const Text('Log out',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.orange)),
              onTap: () => _confirmLogout(context),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 10),
              child: Text('Beef Field Data v0.1 · FCL',
                  style: TextStyle(
                      fontSize: 10, color: Color(0xFF5A5A5A))),
            ),
          ],
        ),
      ),
    );
  }
}