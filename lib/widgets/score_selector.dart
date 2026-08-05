import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The 1-5 score control. Lives here because every section screen needs
/// exactly the same one — checklist, vaccination, performance, records.
class ScoreSelector extends StatelessWidget {
  const ScoreSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  /// e.g. "Vaccination score" — each section names its own.
  final String label;
  final int? value;
  final ValueChanged<int> onChanged;
  final bool showError;

  /// Red at 1 through to dark green at 5, so the scale reads before the
  /// number does.
  static const scoreColors = [
    Color(0xFFE05B4D), // 1 poor
    Color(0xFFE08A4D), // 2 below average
    Color(0xFFD9B84D), // 3 average
    Color(0xFF6FA84F), // 4 good
    Color(0xFF2E7D32), // 5 excellent
  ];

  static String scoreLabel(int score) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (i) {
            final n = i + 1;
            final selected = value == n;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onChanged(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? scoreColors[i]
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        // Unselected pills keep a faint tint of their
                        // own colour, so the whole scale reads
                        // red-to-green at a glance.
                        color: selected
                            ? scoreColors[i]
                            : scoreColors[i].withValues(alpha: 0.35),
                        width: selected ? 1.4 : 0.8,
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
                            : scoreColors[i].withValues(alpha: 0.75),
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
            value == null
                ? 'Tap a score from 1 (poor) to 5 (excellent)'
                : scoreLabel(value!),
            style: TextStyle(
              fontSize: 12,
              color: value == null
                  ? AppColors.textMuted
                  : scoreColors[value! - 1],
            ),
          ),
        ),
        if (showError && value == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Choose a score from 1 to 5',
                style:
                    TextStyle(fontSize: 12, color: AppColors.orange)),
          ),
      ],
    );
  }
}