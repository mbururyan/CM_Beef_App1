import 'package:flutter/material.dart';

import '../constants/evaluation_template.dart';
import '../models/evaluation.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/score_selector.dart';

/// A completed visit, read only. Submitted evaluations are the record
/// FCL works from, so nothing here can be changed — an EO who needs a
/// correction starts a new visit.
class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({super.key, required this.visit});

  final Evaluation visit;

  Color get _ratingColor =>
      ScoreSelector.scoreColors[_bandIndex(visit.rating)];

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
        title: Text(visit.farmName,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Visit facts ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fact('Date',
                        Formatters.date(visit.evaluationDate)),
                    _fact('Location',
                        '${visit.county}${visit.subCounty.isEmpty ? '' : ' · ${visit.subCounty}'}'),
                    _fact('Evaluator',
                        visit.eoName.isEmpty ? '—' : visit.eoName),
                    _fact('Herd',
                        '${visit.totalHerd} head '
                        '(${visit.breedingCows} cows, ${visit.bulls} bulls, '
                        '${visit.calves} calves, ${visit.growersSteers} growers)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Score and rating ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('Total score',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text('${visit.totalScore}/35',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            _ratingColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _ratingColor.withValues(
                                alpha: 0.5),
                            width: 0.8),
                      ),
                      child: Column(
                        children: [
                          const Text('Rating',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(visit.rating.label,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _ratingColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // --- Sections, tap to open the detail of each ---
              const Text('Sections',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              ...SectionKey.values
                  .map((k) => _sectionTile(context, k)),
              const SizedBox(height: 18),

              // --- Closing notes ---
              if (visit.keyStrengths.isNotEmpty) ...[
                _notes('Key strengths', visit.keyStrengths,
                    AppColors.greenLight),
                const SizedBox(height: 14),
              ],
              if (visit.areasImprovement.isNotEmpty) ...[
                _notes('Areas for improvement',
                    visit.areasImprovement, AppColors.amber),
                const SizedBox(height: 14),
              ],
              if (visit.recommendations.isNotEmpty) ...[
                const Text('Recommendations',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(visit.recommendations,
                      style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 18),
              ],

              const Center(
                child: Text(
                  'Submitted visits cannot be edited.',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fact(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );

  /// One collapsed row per section; expanding shows exactly what was
  /// answered on the day.
  Widget _sectionTile(BuildContext context, SectionKey key) {
    final section = visit.sections[key];
    final score = section?.score ?? 0;
    final color =
        ScoreSelector.scoreColors[score.clamp(1, 5) - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Theme(
        // copyWith, NOT a bare ThemeData(): constructing one from
        // scratch replaces the app theme with Flutter's default light
        // theme, and every unstyled Text inside turns black on black.
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding:
              const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: AppColors.textMuted,
          collapsedIconColor: AppColors.textMuted,
          title: Row(
            children: [
              Expanded(
                child: Text(key.label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary)),
              ),
              Text('$score/5',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          children: [
            ..._answerRows(key, section),
            if (section != null && section.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(section.comment,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Turns the stored answer ids back into readable rows, using the
  /// same templates the section screens were built from.
  List<Widget> _answerRows(
      SectionKey key, EvaluationSection? section) {
    if (key == SectionKey.vaccination) {
      if (visit.vaccinations.isEmpty) {
        return [_muted('No vaccination rows recorded')];
      }
      return visit.vaccinations.map((v) {
        final freq = EvaluationTemplate
                .vaccinationFrequencies[v.frequency] ??
            v.frequency;
        final date = v.dateUnknown
            ? 'date unknown'
            : v.lastAdministered == null
                ? 'no date'
                : Formatters.date(v.lastAdministered);
        return _row(v.disease,
            '$freq · $date${v.recordsAvailable ? ' · records seen' : ''}');
      }).toList();
    }

    final answers = section?.answers ?? const {};
    if (answers.isEmpty) return [_muted('Nothing recorded')];

    if (key == SectionKey.performance) {
      final rows = <Widget>[
        for (final q in EvaluationTemplate.performanceChecks)
          if (answers.containsKey(q.id))
            _row(q.text,
                (answers[q.id] as bool?) == true ? 'Yes' : 'No',
                good: (answers[q.id] as bool?) == true),
      ];
      EvaluationTemplate.performanceKpis.forEach((id, meta) {
        if (answers[id] != null) {
          rows.add(_row(meta[0], '${answers[id]} ${meta[1]}'));
        }
      });
      return rows;
    }

    if (key == SectionKey.records) {
      return EvaluationTemplate.recordTypes
          .map((r) => _row(
              r.text, (answers[r.id] as bool?) == true ? 'Kept' : 'Not kept',
              good: (answers[r.id] as bool?) == true))
          .toList();
    }

    final template = EvaluationTemplate.forKey(key);
    if (template == null) return [_muted('Nothing recorded')];
    return template.questions.map((q) {
      final v = answers[q.id] as bool?;
      return _row(
        q.text,
        v == null
            ? '—'
            : v
                ? template.positiveLabel
                : template.negativeLabel,
        good: v == true,
      );
    }).toList();
  }

  Widget _row(String label, String value, {bool? good}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 10),
            Text(value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: good == null
                      ? AppColors.textPrimary
                      : good
                          ? AppColors.greenLight
                          : AppColors.orange,
                )),
          ],
        ),
      );

  Widget _muted(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
      );

  Widget _notes(String title, List<String> items, Color accent) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          ...items.map((i) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                      left: BorderSide(color: accent, width: 3)),
                ),
                child:
                    Text(i, style: const TextStyle(fontSize: 13)),
              )),
        ],
      );
}