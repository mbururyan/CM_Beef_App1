import 'package:flutter/material.dart';

import '../models/evaluation.dart';
import '../models/farm.dart';
import '../services/auth_service.dart';
import '../services/evaluation_service.dart';
import '../services/farm_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/score_selector.dart';
import 'evaluation_hub_screen.dart';
import 'register_farm_screen.dart';
import 'visit_detail_screen.dart';
import 'visit_setup_screen.dart';

class FarmDetailScreen extends StatelessWidget {
  const FarmDetailScreen({super.key, required this.farm});

  /// The farm as it was in the list. The screen then watches the live
  /// document, so an edit shows up here the moment it is saved.
  final Farm farm;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Farm?>(
      stream: FarmService.instance.watchFarm(farm.id),
      initialData: farm,
      builder: (context, snap) {
        final current = snap.data ?? farm;
        final uid = AuthService.instance.currentUser?.uid;
        final canEdit = current.createdBy == uid;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(current.name,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                tooltip: 'Edit farm',
                // Shown to everyone, but dimmed when it will not work —
                // hiding it entirely would leave EOs wondering whether
                // editing exists at all.
                icon: Icon(Icons.edit_outlined,
                    color: canEdit
                        ? AppColors.greenLight
                        : AppColors.textMuted),
                onPressed: () => canEdit
                    ? Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RegisterFarmScreen(
                              existing: current),
                        ),
                      )
                    : _showLockedDialog(context, current),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Farm info ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('County', current.county),
                        _row('Sub-county', current.subCounty),
                        _row('Village', current.locationArea),
                        _row('System',
                            current.productionSystem.label),
                        _row('Owner', current.ownerManager),
                        _row('Phone', current.contactPhone),
                        _row('Registered',
                            Formatters.date(current.createdAt)),
                        _row('Registered by',
                            current.createdByLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            VisitSetupScreen(initialFarm: current),
                      ),
                    ),
                    icon: const Icon(Icons.post_add, size: 20),
                    label: const Text('Evaluate this farm'),
                  ),
                  const SizedBox(height: 24),

                  // --- Visit history: every visit, by any EO ---
                  StreamBuilder<List<Evaluation>>(
                    stream: EvaluationService.instance
                        .byFarm(current.id),
                    builder: (context, vsnap) {
                      if (vsnap.hasError) {
                        return _historyCard(
                            'Could not load visits');
                      }
                      final visits =
                          vsnap.data ?? const <Evaluation>[];
                      final submitted = visits
                          .where((v) => !v.isDraft)
                          .toList();

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text('Visits · ${visits.length}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color:
                                          AppColors.textMuted)),
                              const Spacer(),
                              // Two or more scores make a direction;
                              // one score is just a number.
                              if (submitted.length >= 2)
                                Text(
                                  _trendLabel(submitted),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _trendUp(submitted)
                                        ? AppColors.greenLight
                                        : AppColors.amber,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (visits.isEmpty)
                            _historyCard('No visits recorded yet')
                          else
                            ...visits.map(
                                (v) => _visitRow(context, v)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLockedDialog(
      BuildContext context, Farm current) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cannot edit this farm',
            style: TextStyle(fontSize: 17)),
        content: Text(
          'Only ${current.createdByLabel}, who registered '
          '${current.name}, can change its details. Ask them to '
          'update it — you can still evaluate this farm.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ),
            Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  static Widget _historyCard(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted)),
      );

  /// Newest first, so "improving" means the latest beats the one before.
  static bool _trendUp(List<Evaluation> submitted) =>
      submitted.first.totalScore >= submitted[1].totalScore;

  static String _trendLabel(List<Evaluation> submitted) {
    final diff =
        submitted.first.totalScore - submitted[1].totalScore;
    if (diff == 0) return 'no change';
    return diff > 0 ? 'improving +$diff' : 'declining $diff';
  }

  Widget _visitRow(BuildContext context, Evaluation v) {
    final color = v.isDraft
        ? AppColors.amber
        : ScoreSelector.scoreColors[_bandIndex(v.rating)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        // Drafts resume in the wizard; submitted visits open read only.
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => v.isDraft
                ? EvaluationHubScreen(evaluationId: v.id)
                : VisitDetailScreen(visit: v),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border:
                Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formatters.date(v.evaluationDate),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(v.eoName.isEmpty ? '—' : v.eoName,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (v.isDraft)
                Text('${v.progressLabel} · resume',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.amber))
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: color.withValues(alpha: 0.55),
                        width: 0.8),
                  ),
                  child: Text('${v.totalScore}/35',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static int _bandIndex(Rating r) {
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
}