import 'package:flutter/material.dart';

import '../constants/kenya_locations.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class RegisterFarmScreen extends StatefulWidget {
  const RegisterFarmScreen({super.key, this.existing});

  /// When set, the screen edits this farm instead of creating one.
  /// Same fields, same validation — only the write differs.
  final Farm? existing;

  @override
  State<RegisterFarmScreen> createState() => _RegisterFarmScreenState();
}

class _RegisterFarmScreenState extends State<RegisterFarmScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _county;
  String? _subCounty;
  ProductionSystem? _system;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    if (f == null) return;
    _nameCtrl.text = f.name;
    _areaCtrl.text = f.locationArea;
    _ownerCtrl.text = f.ownerManager;
    _phoneCtrl.text = f.contactPhone;
    _county = f.county.isEmpty ? null : f.county;
    _subCounty = f.subCounty.isEmpty ? null : f.subCounty;
    _system = f.productionSystem;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    final name = _nameCtrl.text.trim();

    // Editing takes the simple path: one update, no sync race, because
    // the farm already exists on this device either way.
    if (_isEdit) {
      FarmService.instance.updateFarm(
        farmId: widget.existing!.id,
        name: name,
        county: _county!,
        subCounty: _subCounty!,
        locationArea: _areaCtrl.text,
        ownerManager: _ownerCtrl.text,
        contactPhone: _phoneCtrl.text,
        productionSystem: _system!,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name updated'),
          backgroundColor: AppColors.green,
        ),
      );
      return;
    }

    String? error;
    bool synced = false;
    try {
      final result = FarmService.instance.createFarm(
        name: name,
        county: _county!,
        subCounty: _subCounty!,
        locationArea: _areaCtrl.text,
        ownerManager: _ownerCtrl.text,
        contactPhone: _phoneCtrl.text,
        productionSystem: _system!,
      );
      // The farm is already saved on this phone. This only asks whether
      // the server got it too, so we can tell the EO the truth.
      synced = await result.syncedWithin(const Duration(seconds: 2));
    } catch (_) {
      error = 'Could not save the farm — try again';
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.orange),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? '$name registered and synced'
              : '$name saved on this phone — will sync when online',
        ),
        backgroundColor: synced ? AppColors.green : AppColors.amber,
        duration: const Duration(seconds: 4),
      ),
    );
    Navigator.of(context).pop();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final subcounties = KenyaLocations.subcountiesOf(_county);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_isEdit ? 'Edit farm' : 'Register farm',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Farm name'),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'e.g. Lion Hills Farm'),
                  validator: (v) => Validators.required(v, 'Farm name'),
                ),
                const SizedBox(height: 16),

                _label('County'),
                DropdownButtonFormField<String>(
                  initialValue: _county,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  hint: const Text('Select county',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textMuted)),
                  items: KenyaLocations.counties
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _county = v;
                    // Clear the subcounty: the old one belongs to the
                    // county the user just moved away from.
                    _subCounty = null;
                  }),
                  // Overrides the form's on-blur rule. Opening and
                  // closing a dropdown counts as losing focus, which
                  // would scold the EO before they had a chance to
                  // choose. This waits for the Save button, then clears
                  // itself the moment a county is picked.
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) =>
                      v == null ? 'County cannot be blank' : null,
                ),
                const SizedBox(height: 16),

                _label('Sub-county'),
                DropdownButtonFormField<String>(
                  initialValue: _subCounty,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  hint: Text(
                    _county == null
                        ? 'Pick a county first'
                        : 'Select sub-county',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textMuted),
                  ),
                  items: subcounties
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  // Disabled until a county is chosen: a null handler
                  // is Flutter's way of greying out a dropdown.
                  onChanged: _county == null
                      ? null
                      : (v) => setState(() => _subCounty = v),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) =>
                      v == null ? 'Sub-county cannot be blank' : null,
                ),
                const SizedBox(height: 16),

                _label('Village / locality (optional)'),
                TextFormField(
                  controller: _areaCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'e.g. Maraba'),
                ),
                const SizedBox(height: 16),

                _label('Owner / manager'),
                TextFormField(
                  controller: _ownerCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'Name of contact person'),
                  validator: (v) =>
                      Validators.required(v, 'Owner / manager'),
                ),
                const SizedBox(height: 16),

                _label('Contact phone'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                      hintText: '07xx or 01xx, or +254...'),
                  validator: Validators.kenyanPhone,
                ),
                const SizedBox(height: 18),

                _label('Production system'),
                FormField<ProductionSystem>(
                  initialValue: _system,
                  validator: (v) =>
                      v == null ? 'Select a production system' : null,
                  builder: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ProductionSystem.values.map((p) {
                          final selected = _system == p;
                          return ChoiceChip(
                            label: Text(p.label),
                            selected: selected,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? AppColors.greenLight
                                  : AppColors.textSecondary,
                            ),
                            backgroundColor: AppColors.inputFill,
                            selectedColor: AppColors.greenDark,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.green
                                  : AppColors.inputBorder,
                              width: 0.8,
                            ),
                            onSelected: (_) {
                              setState(() => _system = p);
                              state.didChange(p); // clears the error
                            },
                          );
                        }).toList(),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            state.errorText!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.orange),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Save farm'),
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
      ),
    );
  }
}