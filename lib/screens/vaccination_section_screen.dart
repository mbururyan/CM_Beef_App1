import 'package:flutter/material.dart';

import '../constants/evaluation_template.dart';
import '../models/evaluation.dart';
import '../services/evaluation_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/score_selector.dart';

/// Editable state for one disease row. A plain mutable class rather
/// than the immutable VaccinationRecord, because the form edits these
/// in place and only converts to records on save.
class _VaccRow {
  _VaccRow({
    required this.disease,
    this.frequency,
    this.lastAdministered,
    this.dateUnknown = false,
    this.recordsAvailable = false,
    this.custom = false,
  });

  final String disease;
  String? frequency;
  DateTime? lastAdministered;
  bool dateUnknown;
  bool recordsAvailable;

  /// Added by the EO rather than part of the standard set — only these
  /// can be removed.
  final bool custom;

  /// A date is irrelevant when the vaccine was never given.
  bool get needsDate =>
      frequency != null &&
      frequency != 'not_done' &&
      frequency != 'unknown';
}

class VaccinationSectionScreen extends StatefulWidget {
  const VaccinationSectionScreen({
    super.key,
    required this.evaluationId,
    this.existingRecords = const [],
    this.existingSection,
  });

  final String evaluationId;
  final List<VaccinationRecord> existingRecords;
  final EvaluationSection? existingSection;

  @override
  State<VaccinationSectionScreen> createState() =>
      _VaccinationSectionScreenState();
}

class _VaccinationSectionScreenState
    extends State<VaccinationSectionScreen> {
  late List<_VaccRow> _rows;
  final _commentCtrl = TextEditingController();
  int? _score;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();

    // Start from the standard diseases, then fold in anything already
    // saved — including diseases this EO added last time.
    final saved = {
      for (final r in widget.existingRecords) r.disease: r
    };

    _rows = [
      for (final d in EvaluationTemplate.defaultVaccinations)
        _VaccRow(
          disease: d,
          frequency: saved[d]?.frequency,
          lastAdministered: saved[d]?.lastAdministered,
          dateUnknown: saved[d]?.dateUnknown ?? false,
          recordsAvailable: saved[d]?.recordsAvailable ?? false,
        ),
      for (final r in widget.existingRecords)
        if (!EvaluationTemplate.defaultVaccinations
            .contains(r.disease))
          _VaccRow(
            disease: r.disease,
            frequency: r.frequency,
            lastAdministered: r.lastAdministered,
            dateUnknown: r.dateUnknown,
            recordsAvailable: r.recordsAvailable,
            custom: true,
          ),
    ];

    _commentCtrl.text = widget.existingSection?.comment ?? '';
    final s = widget.existingSection?.score ?? 0;
    _score = s == 0 ? null : s;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _allAnswered => _rows.every((r) => r.frequency != null);

  Future<void> _addDisease() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Add vaccine', style: TextStyle(fontSize: 17)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              const InputDecoration(hintText: 'Disease or vaccine name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    // Don't create a second row for something already listed.
    if (_rows.any(
        (r) => r.disease.toLowerCase() == name.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name is already listed'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }
    setState(() =>
        _rows.add(_VaccRow(disease: name, custom: true)));
  }

  Future<void> _pickDate(_VaccRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: row.lastAdministered ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        row.lastAdministered = picked;
        row.dateUnknown = false;
      });
    }
  }

  void _save() {
    if (!_allAnswered || _score == null) {
      setState(() => _showErrors = true);
      return;
    }

    EvaluationService.instance.saveVaccinationSection(
      widget.evaluationId,
      records: _rows
          .map((r) => VaccinationRecord(
                disease: r.disease,
                frequency: r.frequency!,
                lastAdministered:
                    r.needsDate && !r.dateUnknown
                        ? r.lastAdministered
                        : null,
                dateUnknown: r.needsDate && r.dateUnknown,
                recordsAvailable: r.recordsAvailable,
              ))
          .toList(),
      comment: _commentCtrl.text,
      score: _score!,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vaccination saved'),
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
        title: const Text('Vaccination',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._rows.map(_diseaseCard),

              // --- Add another vaccine ---
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _addDisease,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.inputBorder,
                        width: 0.8,
                        style: BorderStyle.solid),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add,
                          size: 18, color: AppColors.greenLight),
                      SizedBox(width: 6),
                      Text('Add another vaccine',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.greenLight)),
                    ],
                  ),
                ),
              ),

              if (_showErrors && !_allAnswered)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                      'Choose a frequency for every vaccine above',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.orange)),
                ),
              const SizedBox(height: 22),

              ScoreSelector(
                label: 'Vaccination score',
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

  Widget _diseaseCard(_VaccRow row) {
    final missing = _showErrors && row.frequency == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: missing
            ? Border.all(color: AppColors.orange, width: 0.8)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.disease,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              if (row.custom)
                InkWell(
                  onTap: () => setState(() => _rows.remove(row)),
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: row.frequency,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            hint: const Text('How often?',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
            items: EvaluationTemplate.vaccinationFrequencies.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => row.frequency = v),
          ),

          // A date only makes sense when the vaccine is actually given.
          if (row.needsDate) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: row.dateUnknown
                        ? null
                        : () => _pickDate(row),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.inputBorder,
                            width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.dateUnknown
                                  ? 'Date not known'
                                  : row.lastAdministered == null
                                      ? 'Last administered'
                                      : Formatters.date(
                                          row.lastAdministered),
                              style: TextStyle(
                                fontSize: 13,
                                color: row.dateUnknown ||
                                        row.lastAdministered == null
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // "Unsure" is an honest answer, not a missing one — better
            // than an EO guessing a date to fill the field.
            _CheckRow(
              label: 'Farmer unsure of the date',
              value: row.dateUnknown,
              onChanged: (v) => setState(() {
                row.dateUnknown = v;
                if (v) row.lastAdministered = null;
              }),
            ),
          ],

          _CheckRow(
            label: 'Written records seen',
            value: row.recordsAvailable,
            onChanged: (v) =>
                setState(() => row.recordsAvailable = v),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                side: const BorderSide(
                    color: AppColors.inputBorder, width: 1.2),
                activeColor: AppColors.green,
              ),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}