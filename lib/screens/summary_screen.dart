import 'package:flutter/material.dart';

import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/score_selector.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.evaluation});

  final Evaluation evaluation;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const _maxItems = 3;

  late List<String> _strengths;
  late List<String> _improvements;
  final _recommendCtrl = TextEditingController();
  bool _showErrors = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _strengths = List<String>.from(widget.evaluation.keyStrengths);
    _improvements =
        List<String>.from(widget.evaluation.areasImprovement);
    _recommendCtrl.text = widget.evaluation.recommendations;
  }

  @override
  void dispose() {
    _recommendCtrl.dispose();
    super.dispose();
  }

  /// Rating takes the colour of the band it sits in, matching the
  /// section scale so the whole app reads the same way.
  Color get _ratingColor {
    switch (widget.evaluation.rating) {
      case Rating.poor:
        return ScoreSelector.scoreColors[0];
      case Rating.fair:
        return ScoreSelector.scoreColors[2];
      case Rating.good:
        return ScoreSelector.scoreColors[3];
      case Rating.excellent:
        return ScoreSelector.scoreColors[4];
    }
  }

  Future<void> _addItem(List<String> target, String title) async {
    if (target.length >= _maxItems) return;
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 17)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Keep it short'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    setState(() => target.add(text));
  }

  Future<void> _submit() async {
    if (_recommendCtrl.text.trim().isEmpty) {
      setState(() => _showErrors = true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit visit?', style: TextStyle(fontSize: 17)),
        content: Text(
          '${widget.evaluation.farmName} scored '
          '${widget.evaluation.totalScore}/35 — '
          '${widget.evaluation.rating.label}. '
          'It will move out of your drafts.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);

    EvaluationService.instance.submitWithSummary(
      widget.evaluation,
      keyStrengths: _strengths,
      areasImprovement: _improvements,
      recommendations: _recommendCtrl.text,
    );

    if (!mounted) return;
    // Straight back to Home — the visit is done, and the hub behind us
    // now describes a draft that no longer exists.
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${widget.evaluation.farmName} submitted — '
            '${widget.evaluation.totalScore}/35'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eval = widget.evaluation;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Review and submit',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Visit header ---
              Text(eval.farmName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                '${eval.county} · ${Formatters.date(eval.evaluationDate)} '
                '· ${eval.totalHerd} head',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // --- Score and rating ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                          Text('${eval.totalScore}/35',
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _ratingColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                _ratingColor.withValues(alpha: 0.5),
                            width: 0.8),
                      ),
                      child: Column(
                        children: [
                          const Text('Rating',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(eval.rating.label,
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
              const SizedBox(height: 8),
              const Center(
                child: Text('Calculated from the seven section scores',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 18),

              // --- Section breakdown ---
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: SectionKey.values.map((key) {
                    final score = eval.sections[key]?.score ?? 0;
                    final color = ScoreSelector
                        .scoreColors[score.clamp(1, 5) - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(key.label,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color:
                                        AppColors.textSecondary)),
                          ),
                          Text('$score/5',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),

              // --- Closing notes ---
              _itemList(
                title: 'Key strengths',
                items: _strengths,
                addLabel: 'Add a strength',
                accent: AppColors.greenLight,
              ),
              const SizedBox(height: 16),
              _itemList(
                title: 'Areas for improvement',
                items: _improvements,
                addLabel: 'Add an area',
                accent: AppColors.amber,
              ),
              const SizedBox(height: 16),

              const Text('Recommendations and action plan',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _recommendCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    hintText:
                        'What the farmer should do next — this reaches them'),
              ),
              if (_showErrors && _recommendCtrl.text.trim().isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Recommendations cannot be blank',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.orange)),
                ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit visit'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Saves on this phone straight away and syncs when online.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Up to three short bullet points, added one at a time.
  Widget _itemList({
    required String title,
    required List<String> items,
    required String addLabel,
    required Color accent,
  }) {
    final full = items.length >= _maxItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${items.length}/$_maxItems',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                    left: BorderSide(color: accent, width: 3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  InkWell(
                    onTap: () => setState(() => items.remove(item)),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            )),
        if (!full)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _addItem(items, addLabel),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.inputBorder, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(addLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}