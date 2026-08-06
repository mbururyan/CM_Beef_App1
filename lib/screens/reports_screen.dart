import 'package:flutter/material.dart';

import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/score_selector.dart';
import 'visit_detail_screen.dart';

/// Every completed visit, framed as documents rather than records —
/// this is where an EO comes when a farmer asks for their report again.
///
/// The Visits tab answers "what have I done"; this answers "what can I
/// send". Same data, different question, which is why both exist.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Future<void> _comingSoon(BuildContext context, Evaluation v) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Coming soon',
            style: TextStyle(fontSize: 17)),
        content: Text(
          'The report for ${v.farmName} will be downloadable as a '
          'one-page PDF once the report module is ready.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('My reports',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Evaluation>>(
          stream:
              EvaluationService.instance.mySubmitted(limit: 100),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Text('Could not load reports',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              );
            }
            if (!snap.hasData) {
              return const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.4));
            }

            final visits = snap.data!;
            if (visits.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined,
                        size: 38, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text('No reports yet',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Submit a visit and it appears here',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted)),
                  ],
                ),
              );
            }

            final items = <Widget>[];
            String? lastKey;
            for (final v in visits) {
              final key =
                  '${_months[v.evaluationDate.month - 1]} '
                  '${v.evaluationDate.year}';
              if (key != lastKey) {
                items.add(Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8, top: 6),
                  child: Text(key.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted)),
                ));
                lastKey = key;
              }
              items.add(_reportRow(context, v));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: items,
            );
          },
        ),
      ),
    );
  }

  Widget _reportRow(BuildContext context, Evaluation v) {
    final color =
        ScoreSelector.scoreColors[_bandIndex(v.rating)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        // Tapping the row reads the visit; the icon is the export.
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => VisitDetailScreen(visit: v)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 20, color: AppColors.greenLight),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.farmName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.date(v.evaluationDate)} · '
                      '${v.totalScore}/35',
                      style: TextStyle(
                          fontSize: 11, color: color),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Download PDF',
                icon: const Icon(Icons.download_outlined,
                    size: 20, color: AppColors.textMuted),
                onPressed: () => _comingSoon(context, v),
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