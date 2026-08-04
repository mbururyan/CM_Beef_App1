import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/sync_service.dart';
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
    SessionService.instance.clear();
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
    //final uid = AuthService.instance.currentUser!.uid;

    return Drawer(
      backgroundColor: const Color(0xFF181818),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Profile card (from the in-memory session) ---
            Padding(
              padding: const EdgeInsets.all(14),
              child: Builder(
                builder: (context) {
                  final profile = SessionService.instance.profile;
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
                          child: Text(
                            profile.initials,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${profile.username} · ${profile.role}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Sync center carries a live badge of what is still pending.
            StreamBuilder<SyncStatus>(
              stream: SyncService.instance.watch(),
              initialData: SyncStatus.empty,
              builder: (context, snapshot) {
                final count = (snapshot.data ?? SyncStatus.empty).count;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    count == 0
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    size: 20,
                    color: count == 0
                        ? AppColors.textSecondary
                        : AppColors.amber,
                  ),
                  title: const Text('Sync center',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                  trailing: count == 0
                      ? null
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.amberDark,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.amber),
                          ),
                        ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(count == 0
                            ? 'Everything is synced'
                            : '$count item(s) waiting — they sync automatically'),
                      ),
                    );
                  },
                );
              },
            ),
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