import 'package:flutter/material.dart';

import '../../models/evaluation.dart';
import '../../services/evaluation_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/score_selector.dart';
import '../../widgets/sync_strip.dart';
import '../evaluation_hub_screen.dart';
import '../visit_detail_screen.dart';
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
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.greenDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      profile.role,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.greenLight),
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
                debugPrint('drafts stream error: ${snap.error}');
                return _emptyCard('Could not load your drafts');
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
                    child: Text('Unfinished visits',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted)),
                  ),
                  ...drafts.map((d) => _DraftCard(draft: d)),
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
                  Text('Start evaluation',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  SizedBox(height: 2),
                  Text('works offline · syncs later',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFFCDE7CE))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // --- Submitted visits drive both sections below ---
          StreamBuilder<List<Evaluation>>(
            stream: EvaluationService.instance.mySubmitted(),
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('visits stream error: ${snap.error}');
                return _emptyCard('Could not load your visits');
              }
              final visits = snap.data ?? const <Evaluation>[];

              // Farms scoring fair or poor deserve a follow-up. One
              // entry per farm — the newest visit is the current truth.
              final flagged = <String, Evaluation>{};
              for (final v in visits) {
                if (v.rating == Rating.poor ||
                    v.rating == Rating.fair) {
                  flagged.putIfAbsent(v.farmId, () => v);
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Last visit',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  if (visits.isEmpty)
                    _emptyCard('No visits yet')
                  else
                    _VisitCard(visit: visits.first),
                  const SizedBox(height: 16),

                  const Text('Needs attention',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  if (flagged.isEmpty)
                    _emptyCard('Nothing needs attention yet')
                  else
                    ...flagged.values
                        .take(3)
                        .map((v) => _AttentionCard(visit: v)),
                ],
              );
            },
          ),
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
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted)),
      );
}

/// An unfinished visit. Swipe right to discard, tap to resume.
class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});

  final Evaluation draft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(draft.id),
        // Confirmed first, because a swipe in a pocket should never
        // destroy half a visit.
        direction: DismissDirection.startToEnd,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline,
              color: Colors.white, size: 22),
        ),
        confirmDismiss: (_) async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Discard visit?',
                  style: TextStyle(fontSize: 17)),
              content: Text(
                'The unfinished visit to ${draft.farmName} '
                '(${draft.progressLabel}) will be deleted. '
                'This cannot be undone.',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Keep'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Discard',
                      style: TextStyle(color: AppColors.orange)),
                ),
              ],
            ),
          );
          return ok ?? false;
        },
        onDismissed: (_) =>
            EvaluationService.instance.deleteDraft(draft.id),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  EvaluationHubScreen(evaluationId: draft.id),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.amber, width: 1),
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
                  child: const Icon(Icons.access_time,
                      size: 20, color: AppColors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(draft.farmName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${draft.progressLabel} done',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.amber)),
                    ],
                  ),
                ),
                const Text('resume',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.amber)),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The most recent completed visit.
class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});

  final Evaluation visit;

  @override
  Widget build(BuildContext context) {
    final color = ScoreSelector
        .scoreColors[_bandIndex(visit.rating)];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => VisitDetailScreen(visit: visit)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(visit.farmName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                    // Still on this phone only — the clock clears
                    // itself the moment the server confirms.
                    if (visit.pendingSync) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time,
                          size: 14, color: AppColors.amber),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${visit.county} · '
                  '${_relative(visit.evaluationDate)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: color.withValues(alpha: 0.55), width: 0.8),
            ),
              child: Text('${visit.totalScore}/35',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A farm whose last visit scored fair or poor.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.visit});

  final Evaluation visit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => VisitDetailScreen(visit: visit)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: const Border(
                left: BorderSide(color: AppColors.amber, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(visit.farmName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
              Text(
                '${visit.totalScore}/35 · '
                '${visit.rating.label.toLowerCase()}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.amber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _bandIndex(Rating r) {
  switch (r) {
    case Rating.poor:
      return 0;
    case Rating.fair:
      return 2;
    case Rating.good:
      return 3;
    case Rating.excellent:
      return 4;
  }
}

String _relative(DateTime d) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (days == 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 7) return '$days days ago';
  return '${d.day}/${d.month}/${d.year}';
}