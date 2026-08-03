import 'package:flutter/material.dart';

import '../models/farm.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class FarmDetailScreen extends StatelessWidget {
  const FarmDetailScreen({super.key, required this.farm});

  /// Passed in from the list. Read-only for now — when farm editing
  /// exists, switch to FarmService.watchFarm(farm.id) so the screen
  /// updates itself.
  final Farm farm;

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          farm.name,
          style:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Farm info ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('County', farm.county),
                    _row('Sub-county', farm.subCounty),
                    _row('Village', farm.locationArea),
                    _row('System', farm.productionSystem.label),
                    _row('Owner', farm.ownerManager),
                    _row('Phone', farm.contactPhone),
                    _row('Registered', Formatters.date(farm.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Visit history (real once evaluations exist) ---
              const Text('Visits',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 28, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'No visits recorded yet',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Evaluations arrive in the next module',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  // TODO(evaluation-module): open visit setup with this
                  // farm pre-selected.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Visit setup arrives with the evaluation module'),
                    ),
                  );
                },
                icon: const Icon(Icons.post_add, size: 20),
                label: const Text('Evaluate this farm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}