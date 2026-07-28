import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FarmsTab extends StatelessWidget {
  const FarmsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined,
              size: 40, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text('My farms',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Farm registry arrives in the next module',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}