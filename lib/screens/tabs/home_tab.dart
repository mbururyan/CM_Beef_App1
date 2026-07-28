import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser!.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header: name + role from the users doc, drawer button ---
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future:
                FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final name = data?['full_name'] as String? ?? '…';
              final role = data?['role'] as String? ?? 'evaluator';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $name',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.greenLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu,
                        color: AppColors.textSecondary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // --- Sync strip (static until the sync module) ---
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_done_outlined,
                    size: 16, color: AppColors.greenLight),
                SizedBox(width: 6),
                Text(
                  'All visits synced',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Spacer(),
                Text(
                  'online',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // --- Primary action ---
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // TODO(evaluation-module): open visit setup.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Visit setup arrives with the evaluation module'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.green, AppColors.greenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.post_add, size: 28, color: Colors.white),
                  SizedBox(height: 6),
                  Text(
                    'Start evaluation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'works offline · syncs later',
                    style:
                        TextStyle(fontSize: 11, color: Color(0xFFCDE7CE)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // --- Last visit (real once evaluations exist) ---
          const Text(
            'Last visit',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          _emptyCard('No visits yet'),
          const SizedBox(height: 16),

          // --- Needs attention (real once evaluations exist) ---
          const Text(
            'Needs attention',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          _emptyCard('Nothing needs attention yet'),
          const SizedBox(height: 16),

          // --- Drafts (real once evaluations exist) ---
          const Text(
            'Drafts',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          _emptyCard('No draft evaluations'),
        ],
      ),
    );
  }

  static Widget _emptyCard(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
}