import 'package:flutter/material.dart';

import '../../models/farm.dart';
import '../../services/farm_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../farm_detail_screen.dart';
import '../register_farm_screen.dart';

class FarmsTab extends StatefulWidget {
  const FarmsTab({super.key});

  @override
  State<FarmsTab> createState() => _FarmsTabState();
}

class _FarmsTabState extends State<FarmsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Case-insensitive match across the fields an EO would search by.
  bool _matches(Farm f) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return f.name.toLowerCase().contains(q) ||
        f.county.toLowerCase().contains(q) ||
        f.subCounty.toLowerCase().contains(q) ||
        f.locationArea.toLowerCase().contains(q) ||
        f.ownerManager.toLowerCase().contains(q);
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterFarmScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Farm>>(
      stream: FarmService.instance.allFarms(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _centered(
            icon: Icons.error_outline,
            title: 'Could not load farms',
            subtitle: 'Pull down after checking your connection',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.4),
          );
        }

        final all = snapshot.data!;
        final farms = all.where(_matches).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Row(
                children: [
                  Text(
                    'Farms',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${all.length}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Register farm',
                    icon: const Icon(Icons.add_location_alt_outlined,
                        color: AppColors.greenLight),
                    onPressed: _openRegister,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // --- Search ---
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search farm, county or owner…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 14),

              if (all.isEmpty)
                Expanded(
                  child: _centered(
                    icon: Icons.location_off_outlined,
                    title: 'No farms registered yet',
                    subtitle: 'Register the first farm to get started',
                    action: ElevatedButton.icon(
                      onPressed: _openRegister,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Register farm'),
                    ),
                  ),
                )
              else if (farms.isEmpty)
                Expanded(
                  child: _centered(
                    icon: Icons.search_off,
                    title: 'No matches',
                    subtitle: 'Nothing matches "$_query"',
                  ),
                )
              else ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Newest first',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 18),
                    itemCount: farms.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) => _FarmCard(farm: farms[i]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 38, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FarmDetailScreen(farm: farm)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${farm.locationLabel} · ${farm.productionSystem.label}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'registered ${Formatters.relativeDate(farm.createdAt)} '
                    '· by ${farm.createdByLabel}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}