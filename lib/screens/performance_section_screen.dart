import 'package:flutter/material.dart';

import '../constants/evaluation_template.dart';
import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_chip.dart';
import '../widgets/score_selector.dart';

class PerformanceSectionScreen extends StatefulWidget {
  const PerformanceSectionScreen({
    super.key,
    required this.evaluationId,
    this.existing,
  });

  final String evaluationId;
  final EvaluationSection? existing;

  @override
  State<PerformanceSectionScreen> createState() =>
      _PerformanceSectionScreenState();
}

class _PerformanceSectionScreenState
    extends State<PerformanceSectionScreen> {
  final Map<String, bool?> _checks = {};
  final Map<String, TextEditingController> _kpis = {};
  final _commentCtrl = TextEditingController();
  int? _score;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final prev = widget.existing?.answers ?? const {};

    for (final q in EvaluationTemplate.performanceChecks) {
      _checks[q.id] = prev[q.id] as bool?;
    }
    for (final id in EvaluationTemplate.performanceKpis.keys) {
      final v = prev[id];
      _kpis[id] = TextEditingController(
          text: v == null ? '' : '${(v as num)}');
    }

    _commentCtrl.text = widget.existing?.comment ?? '';
    final s = widget.existing?.score ?? 0;
    _score = s == 0 ? null : s;
  }

  @override
  void dispose() {
    for (final c in _kpis.values) {
      c.dispose();
    }
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _allAnswered => _checks.values.every((v) => v != null);

  void _save() {
    if (!_allAnswered || _score == null) {
      setState(() => _showErrors = true);
      return;
    }

    // Checks and KPI figures share one answers map — the schema keeps
    // section answers free-form precisely so this needs no migration.
    final answers = <String, dynamic>{..._checks};
    _kpis.forEach((id, ctrl) {
      final text = ctrl.text.trim();
      if (text.isEmpty) return; // blank stays absent, not zero
      final parsed = num.tryParse(text);
      if (parsed != null) answers[id] = parsed;
    });

    EvaluationService.instance.saveSection(
      widget.evaluationId,
      EvaluationSection(
        key: SectionKey.performance,
        answers: answers,
        comment: _commentCtrl.text,
        score: _score!,
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance monitoring saved'),
        backgroundColor: AppColors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Performance monitoring',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Practices ---
              ...EvaluationTemplate.performanceChecks.map((q) {
                final value = _checks[q.id];
                final missing = _showErrors && value == null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: missing
                        ? Border.all(
                            color: AppColors.orange, width: 0.8)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.text,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AnswerChip(
                            label: 'Yes',
                            selected: value == true,
                            onTap: () =>
                                setState(() => _checks[q.id] = true),
                          ),
                          const SizedBox(width: 8),
                          AnswerChip(
                            label: 'No',
                            positive: false,
                            selected: value == false,
                            onTap: () =>
                                setState(() => _checks[q.id] = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),

              // --- Figures ---
              const Text('Figures (leave blank if not known)',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              ...EvaluationTemplate.performanceKpis.entries.map((e) {
                final label = e.value[0];
                final unit = e.value[1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _kpis[e.key],
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: '—',
                            suffixText: unit,
                            suffixStyle: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              if (_showErrors && !_allAnswered)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Answer every question above',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.orange)),
                ),
              const SizedBox(height: 18),

              ScoreSelector(
                label: 'Performance monitoring score',
                value: _score,
                onChanged: (n) => setState(() => _score = n),
                showError: _showErrors,
              ),
              const SizedBox(height: 20),

              const Text('Comments',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText:
                        'Observations for FCL — not shown to the farmer'),
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Save section'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
