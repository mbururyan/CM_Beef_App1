import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// One thing waiting to reach the server.
class PendingItem {
  const PendingItem({required this.label, required this.detail});

  /// "New farm: Kiptum Ranch"
  final String label;

  /// "registered offline"
  final String detail;
}

/// A snapshot of how this device stands with the server.
class SyncStatus {
  const SyncStatus({required this.pending, required this.fromCache});

  final List<PendingItem> pending;

  /// True when Firestore answered from the local cache rather than the
  /// server — the closest honest signal we have for "offline".
  final bool fromCache;

  int get count => pending.length;
  bool get allSynced => pending.isEmpty;

  static const empty = SyncStatus(pending: [], fromCache: false);
}

/// Watches for writes this device has made but the server has not yet
/// acknowledged.
///
/// Firestore tracks this itself: every document carries
/// metadata.hasPendingWrites, true from the moment you write locally
/// until the server confirms. We do not guess from connectivity —
/// having signal is not the same as having delivered.
class SyncService {
  SyncService._();
  static final instance = SyncService._();

  final _db = FirebaseFirestore.instance;

  /// Live sync status for this evaluator.
  ///
  /// includeMetadataChanges is essential: without it Firestore only
  /// emits when the DATA changes, so the moment a pending write is
  /// finally acknowledged would never reach the UI.
  // TODO(evaluation-module): fold pending evaluations in here too.
  Stream<SyncStatus> watch() {
    final uid = AuthService.instance.currentUser!.uid;

    return _db
        .collection('farms')
        .where('created_by', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map((snap) {
      final pending = snap.docs
          .where((d) => d.metadata.hasPendingWrites)
          .map((d) => PendingItem(
                label: 'New farm: ${d.data()['name'] ?? 'Unnamed farm'}',
                detail: 'waiting to sync',
              ))
          .toList();

      return SyncStatus(
        pending: pending,
        fromCache: snap.metadata.isFromCache,
      );
    });
  }
}