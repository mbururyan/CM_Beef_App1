import 'package:flutter/material.dart';

import '../services/sync_service.dart';
import '../theme/app_theme.dart';

/// The Home strip that tells an EO whether their work has reached the
/// server. Collapsed by default; tap to see exactly what is waiting.
class SyncStrip extends StatefulWidget {
  const SyncStrip({super.key});

  @override
  State<SyncStrip> createState() => _SyncStripState();
}

class _SyncStripState extends State<SyncStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService.instance.watch(),
      initialData: SyncStatus.empty,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.empty;
        final pending = status.count;
        final synced = status.allSynced;

        final icon = synced
            ? Icons.cloud_done_outlined
            : Icons.cloud_upload_outlined;
        final tint = synced ? AppColors.greenLight : AppColors.amber;
        final text = synced
            ? 'All work synced'
            : '$pending ${pending == 1 ? "item" : "items"} pending';
        final connection = status.fromCache ? 'offline' : 'online';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                // Nothing to expand when everything is synced.
                onTap: synced
                    ? null
                    : () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: tint),
                      const SizedBox(width: 6),
                      Text(
                        text,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        connection,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (!synced)
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                    ],
                  ),
                ),
              ),
              if (_expanded && !synced)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(
                          height: 10,
                          thickness: 0.5,
                          color: Color(0xFF2E2E2E)),
                      ...status.pending.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '· ${p.label}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Saved on this phone. Syncs automatically when back online.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.greenLight),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}