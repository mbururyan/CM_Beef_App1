import 'package:flutter/material.dart';

import '../../models/evaluation.dart';
import '../../services/evaluation_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sync_strip.dart';
import '../evaluation_hub_screen.dart';
import '../visit_setup_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Read straight from the in-memory session — no async, no spinner,
    // works offline.
    final profile = SessionService.instance.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header: name + role, drawer button ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${profile.fullName}',
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
                      profile.role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.greenLight,
                      ),
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (ctx) => IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu,
                      color: AppColors.textSecondary),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // --- Sync strip: live pending-write status ---
          const SyncStrip(),
          const SizedBox(height: 14),

          // --- Unfinished visits sit ABOVE the new-visit button:
          //     finishing what is open outranks starting more. ---
          StreamBuilder<List<Evaluation>>(
            stream: EvaluationService.instance.myDrafts(),
            builder: (context, snap) {
              if (snap.hasError) {
                // Loud on purpose during the build — this is usually a
                // missing composite index, not an absence of drafts.
                return _emptyCard('Drafts error: ${snap.error}');
              }
              final drafts = snap.data ?? const <Evaluation>[];
              // Nothing unfinished: the section disappears entirely
              // rather than showing an empty placeholder.
              if (drafts.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Unfinished visits',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  Column(
                children: drafts
                    .map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EvaluationHubScreen(
                                    evaluationId: d.id),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                // Full outline, not just an edge: an
                                // unfinished visit should read as one
                                // object, not a list row.
                                border: Border.all(
                                    color: AppColors.amber, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.amberDark,
                                    ),
                                    child: const Icon(
                                        Icons.access_time,
                                        size: 20,
                                        color: AppColors.amber),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(d.farmName,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('${d.progressLabel} done',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.amber)),
                                      ],
                                    ),
                                  ),
                                  const Text('resume',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.amber)),
                                  const Icon(Icons.chevron_right,
                                      size: 18,
                                      color: AppColors.amber),
                                ],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            },
          ),

          // --- Primary action ---
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const VisitSetupScreen()),
            ),
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