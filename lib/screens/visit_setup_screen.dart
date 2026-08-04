import 'package:flutter/material.dart';

import '../models/evaluation.dart';
import '../models/farm.dart';
import '../services/evaluation_service.dart';
import '../services/farm_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'evaluation_hub_screen.dart';

class VisitSetupScreen extends StatefulWidget {
  const VisitSetupScreen({super.key, this.initialFarm});

  /// Pre-selected when arriving from a farm's detail screen.
  final Farm? initialFarm;

  @override
  State<VisitSetupScreen> createState() => _VisitSetupScreenState();
}

class _VisitSetupScreenState extends State<VisitSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cowsCtrl = TextEditingController(text: '0');
  final _bullsCtrl = TextEditingController(text: '0');
  final _calvesCtrl = TextEditingController(text: '0');
  final _growersCtrl = TextEditingController(text: '0');

  // One focus node per count field: on focus we clear a lone "0" so the
  // EO types 5 instead of 05, and on blur we put it back so the field is
  // never left looking empty.
  late final List<FocusNode> _countFocus;

  Farm? _farm;
  DateTime _date = DateTime.now();
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _farm = widget.initialFarm;

    final controllers = [
      _cowsCtrl,
      _bullsCtrl,
      _calvesCtrl,
      _growersCtrl
    ];
    _countFocus = List.generate(4, (i) {
      final node = FocusNode();
      node.addListener(() {
        final c = controllers[i];
        if (node.hasFocus) {
          if (c.text == '0') c.clear();
        } else {
          if (c.text.trim().isEmpty) c.text = '0';
        }
        setState(() {});
      });
      return node;
    });
  }

  @override
  void dispose() {
    _cowsCtrl.dispose();
    _bullsCtrl.dispose();
    _calvesCtrl.dispose();
    _growersCtrl.dispose();
    for (final n in _countFocus) {
      n.dispose();
    }
    super.dispose();
  }

  int _num(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  int get _totalHerd =>
      _num(_cowsCtrl) +
      _num(_bullsCtrl) +
      _num(_calvesCtrl) +
      _num(_growersCtrl);

  Future<void> _pickFarm() async {
    final chosen = await showModalBottomSheet<Farm>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _FarmPickerSheet(),
    );
    if (chosen != null) setState(() => _farm = chosen);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      // A visit cannot happen in the future.
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _start() async {
    if (_farm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a farm first'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _starting = true);

    // Draft guard: resume an unfinished visit rather than silently
    // creating a second one for the same farm.
    Evaluation? existing;
    try {
      existing =
          await EvaluationService.instance.openDraftForFarm(_farm!.id);
    } catch (_) {
      // Offline with nothing cached — proceed and let them start fresh.
    }

    if (!mounted) return;

    if (existing != null) {
      final resume = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Unfinished visit',
              style: TextStyle(fontSize: 17)),
          content: Text(
            'You have a draft for ${_farm!.name} at '
            '${existing!.progressLabel} sections. Resume it?',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Start new'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Resume'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (resume == true) {
        setState(() => _starting = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                EvaluationHubScreen(evaluationId: existing!.id),
          ),
        );
        return;
      }
    }

    final id = EvaluationService.instance.createDraft(
      farm: _farm!,
      evaluationDate: _date,
      breedingCows: _num(_cowsCtrl),
      bulls: _num(_bullsCtrl),
      calves: _num(_calvesCtrl),
      growersSteers: _num(_growersCtrl),
    );

    if (!mounted) return;
    setState(() => _starting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EvaluationHubScreen(evaluationId: id),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      );

  Widget _countField(
    String label,
    TextEditingController c,
    FocusNode node,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextFormField(
            controller: c,
            focusNode: node,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}), // keeps the total live
            decoration: const InputDecoration(hintText: '0'),
            validator: (v) {
              final t = (v ?? '').trim();
              // Empty is fine — it means none, and blur restores the 0.
              if (t.isEmpty) return null;
              return int.tryParse(t) == null ? 'Numbers only' : null;
            },
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('New evaluation',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Farm'),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _pickFarm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.inputBorder, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _farm == null
                              ? const Text('Select a farm',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted))
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(_farm!.name,
                                        style: const TextStyle(
                                            fontSize: 14)),
                                    Text(_farm!.locationLabel,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors
                                                .textMuted)),
                                  ],
                                ),
                        ),
                        const Icon(Icons.search,
                            size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _label('Evaluation date'),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.inputBorder, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(Formatters.date(_date),
                              style: const TextStyle(fontSize: 14)),
                        ),
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Herd composition',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _countField('Breeding cows', _cowsCtrl,
                            _countFocus[0])),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _countField(
                            'Bulls', _bullsCtrl, _countFocus[1])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _countField(
                            'Calves', _calvesCtrl, _countFocus[2])),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _countField('Growers / steers',
                            _growersCtrl, _countFocus[3])),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total herd',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                      Text('$_totalHerd',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _starting ? null : _start,
                  child: _starting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Start evaluation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Searchable farm chooser. Reuses the same live farms stream as the
/// Farms tab, so it works offline and shows every registered farm.
class _FarmPickerSheet extends StatefulWidget {
  const _FarmPickerSheet();

  @override
  State<_FarmPickerSheet> createState() => _FarmPickerSheetState();
}

class _FarmPickerSheetState extends State<_FarmPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose farm',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: const InputDecoration(
              hintText: 'Search farm, county or owner…',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: StreamBuilder<List<Farm>>(
              stream: FarmService.instance.allFarms(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4));
                }
                final q = _query.toLowerCase();
                final farms = snap.data!
                    .where((f) =>
                        q.isEmpty ||
                        f.name.toLowerCase().contains(q) ||
                        f.county.toLowerCase().contains(q) ||
                        f.subCounty.toLowerCase().contains(q) ||
                        f.ownerManager.toLowerCase().contains(q))
                    .toList();

                if (farms.isEmpty) {
                  return const Center(
                    child: Text('No farms match',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted)),
                  );
                }

                return ListView.separated(
                  itemCount: farms.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Color(0xFF2E2E2E)),
                  itemBuilder: (context, i) {
                    final f = farms[i];
                    return ListTile(
                      dense: true,
                      title: Text(f.name,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        '${f.locationLabel} · by ${f.createdByLabel}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted),
                      ),
                      onTap: () => Navigator.of(context).pop(f),
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
}