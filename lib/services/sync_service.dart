import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// One thing waiting to reach the server.
class PendingItem {
  const PendingItem({required this.label, required this.detail});

  /// "New farm: VSOP Ranch" / "New farm visit: VSOP Ranch"
  final String label;

  /// "waiting to sync"
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

  /// Live sync status across farms AND evaluations.
  ///
  /// includeMetadataChanges is essential: without it Firestore only
  /// emits when the DATA changes, so the moment a pending write is
  /// finally acknowledged would never reach the UI.
  ///
  /// No created_by / eo_id filter is needed: hasPendingWrites is only
  /// ever true for writes made on THIS device.
  // TODO(scale): fine for a pilot; if the collections grow large,
  // narrow these listeners to the signed-in evaluator.
  Stream<SyncStatus> watch() {
    final controller = StreamController<SyncStatus>();

    var farmItems = <PendingItem>[];
    var visitItems = <PendingItem>[];
    var farmsCached = false;
    var visitsCached = false;

    StreamSubscription? farmSub;
    StreamSubscription? visitSub;

    void emit() {
      if (controller.isClosed) return;
      controller.add(SyncStatus(
        pending: [...farmItems, ...visitItems],
        fromCache: farmsCached || visitsCached,
      ));
    }

    controller.onListen = () {
      farmSub = _db
          .collection('farms')
          .snapshots(includeMetadataChanges: true)
          .listen((snap) {
        farmItems = snap.docs
            .where((d) => d.metadata.hasPendingWrites)
            .map((d) => PendingItem(
                  label:
                      'New farm: ${d.data()['name'] ?? 'Unnamed farm'}',
                  detail: 'waiting to sync',
                ))
            .toList();
        farmsCached = snap.metadata.isFromCache;
        emit();
      });

      visitSub = _db
          .collection('evaluations')
          .snapshots(includeMetadataChanges: true)
          .listen((snap) {
        visitItems = snap.docs
            .where((d) => d.metadata.hasPendingWrites)
            .map((d) {
          final data = d.data();
          final farm = data['farm_name'] ?? 'Unknown farm';
          final submitted = data['status'] == 'submitted';
          return PendingItem(
            // A finished visit and a half-done one are both unsynced
            // work, but the EO cares about them differently.
            label: submitted
                ? 'New farm visit: $farm'
                : 'Draft visit: $farm',
            detail: 'waiting to sync',
          );
        }).toList();
        visitsCached = snap.metadata.isFromCache;
        emit();
      });
    };

    controller.onCancel = () async {
      await farmSub?.cancel();
      await visitSub?.cancel();
    };

    return controller.stream;
  }
}