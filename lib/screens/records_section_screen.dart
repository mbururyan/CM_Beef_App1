import 'package:flutter/material.dart';

import '../constants/evaluation_template.dart';
import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/score_selector.dart';

class RecordsSectionScreen extends StatefulWidget {
  const RecordsSectionScreen({
    super.key,
    required this.evaluationId,
    this.existing,
  });

  final String evaluationId;
  final EvaluationSection? existing;

  @override
  State<RecordsSectionScreen> createState() =>
      _RecordsSectionScreenState();
}

class _RecordsSectionScreenState extends State<RecordsSectionScreen> {
  /// Every record type is false until ticked. Unlike the checklists
  /// there is no unanswered state — "not kept" is simply unticked.
  final Map<String, bool> _kept = {};
  final _commentCtrl = TextEditingController();
  int? _score;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final prev = widget.existing?.answers ?? const {};
    for (final r in EvaluationTemplate.recordTypes) {
      _kept[r.id] = prev[r.id] as bool? ?? false;
    }
    _commentCtrl.text = widget.existing?.comment ?? '';
    final s = widget.existing?.score ?? 0;
    _score = s == 0 ? null : s;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  int get _keptCount => _kept.values.where((v) => v).length;

  void _save() {
    if (_score == null) {
      setState(() => _showErrors = true);
      return;
    }

    EvaluationService.instance.saveSection(
      widget.evaluationId,
      EvaluationSection(
        key: SectionKey.records,
        answers: Map<String, dynamic>.from(_kept),
        comment: _commentCtrl.text,
        score: _score!,
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Record keeping saved'),
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
        title: const Text('Record keeping',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tick every record the farm actually keeps',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),

              ...EvaluationTemplate.recordTypes.map((r) {
                final kept = _kept[r.id] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        setState(() => _kept[r.id] = !kept),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: kept
                              ? AppColors.green
                              : AppColors.inputBorder,
                          width: kept ? 1 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            kept
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                            color: kept
                                ? AppColors.greenLight
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(r.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kept
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 4),
              Text(
                '$_keptCount of ${EvaluationTemplate.recordTypes.length} kept',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              ScoreSelector(
                label: 'Record keeping score',
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