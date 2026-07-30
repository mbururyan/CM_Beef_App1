import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../register_farm_screen.dart';

class FarmsTab extends StatelessWidget {
  const FarmsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('My farms',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('The live list arrives in the next increment',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const RegisterFarmScreen()),
            ),
            icon: const Icon(Icons.add_location_alt_outlined, size: 20),
            label: const Text('Register new farm'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}