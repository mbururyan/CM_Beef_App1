import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/farm.dart';
import 'auth_service.dart';

/// Everything that touches the farms collection. Screens call these
/// methods and get Farm objects back — they never see Firestore.
class FarmService {
  FarmService._();
  static final instance = FarmService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _farms =>
      _db.collection('farms');

  /// Registers a farm and returns its new id.
  ///
  /// Offline-safe by design: the document id is generated on the
  /// device, so this returns immediately with a real id even with no
  /// signal, and Firestore syncs the write when connectivity returns.
  /// Note we deliberately do NOT await the set() — awaiting it would
  /// hang forever while offline, because the server never acknowledges.
  Future<String> createFarm({
    required String name,
    required String county,
    required String subCounty,
    required String locationArea,
    required String ownerManager,
    required String contactPhone,
    required ProductionSystem productionSystem,
  }) async {
    final uid = AuthService.instance.currentUser!.uid;

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
    );

    final ref = _farms.doc(); // id generated locally, no network needed
    ref.set({
      ...farm.toMap(),
      'created_at': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  /// Live list of the farms this evaluator registered, newest first.
  ///
  /// A stream, not a one-off fetch: the list updates itself when a farm
  /// is added, and Firestore serves it from the local cache first, so
  /// it works offline and fills in instantly.
  Stream<List<Farm>> myFarms() {
    final uid = AuthService.instance.currentUser!.uid;
    return _farms
        .where('created_by', isEqualTo: uid)
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