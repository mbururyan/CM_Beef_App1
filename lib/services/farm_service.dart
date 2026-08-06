import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/farm.dart';
import 'auth_service.dart';
import 'session_service.dart';

/// What createFarm hands back: the id is available immediately, while
/// serverAck completes only once the server has the write. Offline,
/// serverAck simply never completes — which is the point.
class FarmCreateResult {
  const FarmCreateResult({required this.id, required this.serverAck});

  final String id;
  final Future<void> serverAck;

  /// Waits briefly for the server. Returns true if it landed, false if
  /// the write is still queued locally.
  Future<bool> syncedWithin(Duration timeout) async {
    try {
      await serverAck.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Everything that touches the farms collection. Screens call these
/// methods and get Farm objects back — they never see Firestore.
class FarmService {
  FarmService._();
  static final instance = FarmService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _farms =>
      _db.collection('farms');

  /// Registers a farm.
  ///
  /// Offline-safe by design: the document id is generated on the
  /// device, so this returns immediately with a real id even with no
  /// signal, and Firestore syncs the write when connectivity returns.
  /// We deliberately do NOT await the set() — awaiting it would hang
  /// forever while offline, because the server never acknowledges.
  FarmCreateResult createFarm({
    required String name,
    required String county,
    required String subCounty,
    required String locationArea,
    required String ownerManager,
    required String contactPhone,
    required ProductionSystem productionSystem,
  }) {
    final uid = AuthService.instance.currentUser!.uid;
    // Stamped from the in-memory session, never a Firestore read:
    // a read would write a blank name when registering offline.
    final eoName = SessionService.instance.profile.fullName;

    final farm = Farm(
      id: '',
      name: name,
      county: county,
      subCounty: subCounty,
      locationArea: locationArea,
      ownerManager: ownerManager,
      contactPhone: contactPhone,
      productionSystem: productionSystem,
      createdBy: uid,
      createdByName: eoName,
    );

    final ref = _farms.doc(); // id generated locally, no network needed
    final ack = ref.set({
      ...farm.toMap(),
      'created_at': FieldValue.serverTimestamp(),
    });

    return FarmCreateResult(id: ref.id, serverAck: ack);
  }

  /// Updates an existing farm.
  ///
  /// created_by and created_by_name are deliberately NOT written: the
  /// rules reject any change to them, and provenance should survive an
  /// edit. created_at is left alone for the same reason.
  void updateFarm({
    required String farmId,
    required String name,
    required String county,
    required String subCounty,
    required String locationArea,
    required String ownerManager,
    required String contactPhone,
    required ProductionSystem productionSystem,
  }) {
    _farms.doc(farmId).update({
      'name': name.trim(),
      'name_lower': name.trim().toLowerCase(),
      'county': county.trim(),
      'sub_county': subCounty.trim(),
      'location_area': locationArea.trim(),
      'owner_manager': ownerManager.trim(),
      'contact_phone': contactPhone.replaceAll(RegExp(r'\s+'), ''),
      'production_system': productionSystem.value,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Live list of EVERY registered farm, newest first.
  ///
  /// Deliberately not scoped to the signed-in EO: a farm can be visited
  /// by several officers, so created_by is provenance, not ownership.
  /// Scoping it would make it impossible for one EO to evaluate a farm
  /// another registered, which forces duplicate registrations.
  ///
  /// A stream, not a one-off fetch: the list updates itself when a farm
  /// is added, and Firestore serves it from the local cache first, so
  /// it works offline and fills in instantly.
  Stream<List<Farm>> allFarms() {
    return _farms
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Farm.fromDoc).toList());
  }

  /// A single farm, live. Used by the farm detail screen.
  Stream<Farm?> watchFarm(String farmId) {
    return _farms.doc(farmId).snapshots().map(
          (doc) => doc.exists ? Farm.fromDoc(doc) : null,
        );
  }

  /// One-off read, for places that just need the current values.
  Future<Farm?> getFarm(String farmId) async {
    final doc = await _farms.doc(farmId).get();
    return doc.exists ? Farm.fromDoc(doc) : null;
  }
}