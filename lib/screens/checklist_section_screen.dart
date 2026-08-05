import 'package:flutter/material.dart';

import '../constants/evaluation_template.dart';
import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_chip.dart';
import '../widgets/score_selector.dart';

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
                          AnswerChip(
                            label: t.positiveLabel,
                            selected: value == true,
                            positive: true,
                            onTap: () => setState(
                                () => _answers[q.id] = true),
                          ),
                          const SizedBox(width: 8),
                          AnswerChip(
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

              const SizedBox(height: 10),

              // --- Score (before comments: the judgement first) ---
              ScoreSelector(
                label: '${t.key.label} score',
                value: _score,
                onChanged: (n) => setState(() => _score = n),
                showError: _showErrors,
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
              const Text('Comments',
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