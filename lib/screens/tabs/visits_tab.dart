import 'package:flutter/material.dart';

import '../../models/evaluation.dart';
import '../../services/evaluation_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/score_selector.dart';
import '../evaluation_hub_screen.dart';
import '../visit_detail_screen.dart';

/// Every visit this evaluator has done — unfinished ones first, then
/// completed visits grouped by month. Home shows only the latest; this
/// is the full record.
class VisitsTab extends StatefulWidget {
  const VisitsTab({super.key});

  @override
  State<VisitsTab> createState() => _VisitsTabState();
}

class _VisitsTabState extends State<VisitsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(Evaluation v) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return v.farmName.toLowerCase().contains(q) ||
        v.county.toLowerCase().contains(q) ||
        v.subCounty.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('My visits',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search farm or county…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<Evaluation>>(
              stream: EvaluationService.instance.myDrafts(),
              builder: (context, draftSnap) {
                final drafts = (draftSnap.data ?? const <Evaluation>[])
                    .where(_matches)
                    .toList();

                return StreamBuilder<List<Evaluation>>(
                  stream: EvaluationService.instance
                      .mySubmitted(limit: 100),
                  builder: (context, doneSnap) {
                    if (doneSnap.hasError) {
                      return _centered(Icons.error_outline,
                          'Could not load visits', '${doneSnap.error}');
                    }
                    if (!doneSnap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4));
                    }

                    final done =
                        doneSnap.data!.where(_matches).toList();

                    if (drafts.isEmpty && done.isEmpty) {
                      return _centered(
                        Icons.assignment_outlined,
                        _query.isEmpty
                            ? 'No visits yet'
                            : 'No matches',
                        _query.isEmpty
                            ? 'Start an evaluation from the Home tab'
                            : 'Nothing matches "$_query"',
                      );
                    }

                    // Month headers, inserted as the list is built.
                    final items = <Widget>[];
                    if (drafts.isNotEmpty) {
                      items.add(_header('Unfinished'));
                      items.addAll(drafts.map(
                          (d) => _row(d, draft: true)));
                    }

                    String? lastKey;
                    for (final v in done) {
                      final key =
                          '${_months[v.evaluationDate.month - 1]} '
                          '${v.evaluationDate.year}';
                      if (key != lastKey) {
                        items.add(_header(key));
                        lastKey = key;
                      }
                      items.add(_row(v));
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 18),
                      children: items,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 6),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.5,
                color: AppColors.textMuted)),
      );

  Widget _row(Evaluation v, {bool draft = false}) {
    final color = draft
        ? AppColors.amber
        : ScoreSelector.scoreColors[_bandIndex(v.rating)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => draft
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
                    Text(v.farmName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${v.county} · '
                      '${Formatters.date(v.evaluationDate)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (draft)
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

  Widget _centered(IconData icon, String title, String subtitle) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ),
          ],
        ),
      );

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