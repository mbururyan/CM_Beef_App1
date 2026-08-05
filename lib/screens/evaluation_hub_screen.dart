import 'package:flutter/material.dart';

import '../constants/evaluation_template.dart';
import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/score_selector.dart';
import 'checklist_section_screen.dart';
import 'performance_section_screen.dart';
import 'records_section_screen.dart';
import 'summary_screen.dart';
import 'vaccination_section_screen.dart';

/// The spine of a visit: every section reachable in any order, because a
/// real farm visit wanders. Nothing here holds unsaved state — each
/// section writes itself, so leaving at any moment loses nothing.
class EvaluationHubScreen extends StatelessWidget {
  const EvaluationHubScreen({super.key, required this.evaluationId});

  final String evaluationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Evaluation',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: StreamBuilder<Evaluation?>(
          stream: EvaluationService.instance.watch(evaluationId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.4));
            }
            final eval = snap.data;
            if (eval == null) {
              return const Center(
                child: Text('This visit no longer exists',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted)),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Visit header ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(eval.farmName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${eval.county} · '
                          '${Formatters.date(eval.evaluationDate)} · '
                          '${eval.totalHerd} head',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Progress ---
                  Row(
                    children: [
                      Text('${eval.progressLabel} sections done',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      Text('Score so far ${eval.totalScore}/35',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: eval.completedSections /
                          SectionKey.values.length,
                      minHeight: 5,
                      backgroundColor: AppColors.inputBorder,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // --- Sections, any order ---
                  ...SectionKey.values.map((key) {
                    final section = eval.sections[key];
                    return _SectionRow(
                      sectionKey: key,
                      section: section,
                      onTap: () {
                        if (key == SectionKey.vaccination) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  VaccinationSectionScreen(
                                evaluationId: evaluationId,
                                existingRecords: eval.vaccinations,
                                existingSection: section,
                              ),
                            ),
                          );
                          return;
                        }
                        if (key == SectionKey.performance) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PerformanceSectionScreen(
                                evaluationId: evaluationId,
                                existing: section,
                              ),
                            ),
                          );
                          return;
                        }
                        if (key == SectionKey.records) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecordsSectionScreen(
                                evaluationId: evaluationId,
                                existing: section,
                              ),
                            ),
                          );
                          return;
                        }
                        final template =
                            EvaluationTemplate.forKey(key);
                        if (template == null) {
                          // Vaccination, performance and records get
                          // their own screens in the next increment.
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content:
                                Text('${key.label} — screen next'),
                          ));
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChecklistSectionScreen(
                              evaluationId: evaluationId,
                              template: template,
                              existing: section,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    // Submit stays locked until all seven are done, so
                    // the hub shows what is outstanding rather than the
                    // EO discovering it at the end.
                    onPressed: eval.isComplete
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SummaryScreen(evaluation: eval),
                              ),
                            )
                        : null,
                    child: Text(eval.isComplete
                        ? 'Review and submit'
                        : 'Complete all sections to submit'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Every section saves as you go. You can leave and come back.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.sectionKey,
    required this.section,
    required this.onTap,
  });

  final SectionKey sectionKey;
  final EvaluationSection? section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = section != null;
    // A completed row takes the colour of its own score, so the hub
    // reads as a heat map — weak sections stand out without being read.
    final scoreColor = done
        ? ScoreSelector.scoreColors[section!.score.clamp(1, 5) - 1]
        : AppColors.inputBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: scoreColor, width: 3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 18,
                color: done ? scoreColor : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(sectionKey.label,
                    style: const TextStyle(fontSize: 14)),
              ),
              if (done)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: scoreColor.withValues(alpha: 0.55),
                        width: 0.8),
                  ),
                  child: Text('${section!.score}/5',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scoreColor)),
                )
              else
                const Text('not started',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}