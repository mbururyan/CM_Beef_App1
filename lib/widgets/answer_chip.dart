import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single selectable answer pill. Shared by the checklist sections,
/// performance and record keeping so every yes/no in the wizard looks
/// and behaves identically.
class AnswerChip extends StatelessWidget {
  const AnswerChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.positive = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Positive answers highlight green, negative ones orange.
  final bool positive;

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
              color: selected ? activeFg : AppColors.textSecondary,
            )),
      ),
    );
  }
}