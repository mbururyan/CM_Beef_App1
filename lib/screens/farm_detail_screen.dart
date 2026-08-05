import 'package:flutter/material.dart';

import '../models/evaluation.dart';
import '../models/farm.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/score_selector.dart';
import 'evaluation_hub_screen.dart';
import 'visit_detail_screen.dart';

class FarmDetailScreen extends StatelessWidget {
  const FarmDetailScreen({super.key, required this.farm});

  /// Passed in from the list. Read-only for now — when farm editing
  /// exists, switch to FarmService.watchFarm(farm.id) so the screen
  /// updates itself.
  final Farm farm;

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
              ),
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
            border: Border(
                left: BorderSide(color: color, width: 3)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          farm.name,
          style:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
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
                    _row('County', farm.county),
                    _row('Sub-county', farm.subCounty),
                    _row('Village', farm.locationArea),
                    _row('System', farm.productionSystem.label),
                    _row('Owner', farm.ownerManager),
                    _row('Phone', farm.contactPhone),
                    _row('Registered', Formatters.date(farm.createdAt)),
                    _row('Registered by', farm.createdByLabel),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  // TODO(evaluation-module): open visit setup with this
                  // farm pre-selected.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Visit setup arrives with the evaluation module'),
                    ),
                  );
                },
                icon: const Icon(Icons.post_add, size: 20),
                label: const Text('Evaluate this farm'),
              ),
              const SizedBox(height: 24),

              // --- Visit history: every visit to this farm, by any EO ---
              StreamBuilder<List<Evaluation>>(
                stream: EvaluationService.instance.byFarm(farm.id),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _historyCard(
                        'Visits error: ${snap.error}');
                  }
                  final visits = snap.data ?? const <Evaluation>[];
                  final submitted = visits
                      .where((v) => !v.isDraft)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('Visits · ${visits.length}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted)),
                          const Spacer(),
                          // Two or more scores make a direction; one
                          // score is just a number.
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
                        ...visits.map((v) => _visitRow(context, v)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}