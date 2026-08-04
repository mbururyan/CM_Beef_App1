import 'package:flutter/material.dart';

import '../constants/evaluation_template.dart';
import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';

/// One screen, four sections. Feeding, feed quality, biosecurity and
/// housing differ only in their questions and answer labels, so they
/// share this widget rather than existing as four near-identical files.
class ChecklistSectionScreen extends StatefulWidget {
  const ChecklistSectionScreen({
    super.key,
    required this.evaluationId,
    required this.template,
    this.existing,
  });

  final String evaluationId;
  final SectionTemplate template;

  /// Previously saved answers, when the EO is revisiting the section.
  final EvaluationSection? existing;

  @override
  State<ChecklistSectionScreen> createState() =>
      _ChecklistSectionScreenState();
}

class _ChecklistSectionScreenState
    extends State<ChecklistSectionScreen> {
  /// question id -> true (positive) / false (negative) / null (unanswered)
  final Map<String, bool?> _answers = {};
  final _commentCtrl = TextEditingController();
  int? _score;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    // Prefill from whatever was saved before, so reopening a section
    // shows the EO's own answers rather than a blank form.
    for (final q in widget.template.questions) {
      _answers[q.id] = widget.existing?.answers[q.id] as bool?;
    }
    _commentCtrl.text = widget.existing?.comment ?? '';
    _score = widget.existing?.score == 0 ? null : widget.existing?.score;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _allAnswered => _answers.values.every((v) => v != null);

  int get _positiveCount =>
      _answers.values.where((v) => v == true).length;

  void _save() {
    if (!_allAnswered || _score == null) {
      setState(() => _showErrors = true);
      return;
    }

    EvaluationService.instance.saveSection(
      widget.evaluationId,
      EvaluationSection(
        key: widget.template.key,
        answers: Map<String, dynamic>.from(_answers),
        comment: _commentCtrl.text,
        score: _score!,
      ),
    );

    // Saved locally the instant this returns — no spinner, no waiting
    // for a server that may not be reachable.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.template.key.label} saved'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String _scoreLabel(int score) {
    switch (score) {
      case 1:
        return '1 — poor';
      case 2:
        return '2 — below average';
      case 3:
        return '3 — average';
      case 4:
        return '4 — good';
      default:
        return '5 — excellent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(t.key.label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Questions ---
              ...t.questions.map((q) {
                final value = _answers[q.id];
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
                          _AnswerChip(
                            label: t.positiveLabel,
                            selected: value == true,
                            positive: true,
                            onTap: () => setState(
                                () => _answers[q.id] = true),
                          ),
                          const SizedBox(width: 8),
                          _AnswerChip(
                            label: t.negativeLabel,
                            selected: value == false,
                            positive: false,
                            onTap: () => setState(
                                () => _answers[q.id] = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 6),
              // Live tally — a hint for the score, never a substitute:
              // the 1-5 remains the evaluator's judgement.
              Text(
                '$_positiveCount of ${t.questions.length} '
                '${t.positiveLabel.toLowerCase()}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),

              // --- Score (before comments: the judgement first) ---
              const Text('Section score',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (i) {
                  final n = i + 1;
                  final selected = _score == n;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _score = n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.green,
                                      AppColors.greenDark
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color:
                                selected ? null : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.greenLight
                                  : AppColors.inputBorder,
                              width: selected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontSize: selected ? 22 : 19,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _score == null
                      ? 'Tap a score from 1 (poor) to 5 (excellent)'
                      : _scoreLabel(_score!),
                  style: TextStyle(
                    fontSize: 12,
                    color: _score == null
                        ? AppColors.textMuted
                        : AppColors.greenLight,
                  ),
                ),
              ),
              if (_showErrors && _score == null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Choose a score from 1 to 5',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.orange)),
                ),
              if (_showErrors && !_allAnswered)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Answer every question above',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.orange)),
                ),
              const SizedBox(height: 20),

              // --- Comment ---
              const Text('Comments (internal)',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Observations for FCL — not shown to the farmer'),
              ),
              const SizedBox(height: 18),

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

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.label,
    required this.selected,
    required this.positive,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool positive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg =
        positive ? AppColors.greenDark : AppColors.amberDark;
    final activeFg =
        positive ? AppColors.greenLight : AppColors.orange;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeBg : AppColors.inputFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? (positive ? AppColors.green : AppColors.orange)
                : AppColors.inputBorder,
            width: 0.8,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color:
                  selected ? activeFg : AppColors.textSecondary,
            )),
      ),
    );
  }
}