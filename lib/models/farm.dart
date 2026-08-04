import 'package:cloud_firestore/cloud_firestore.dart';

/// The four production systems from the FCL evaluation template.
/// Stored in Firestore as the snake_case `value`; shown in the UI
/// as `label`.
enum ProductionSystem {
  feedlot('feedlot', 'Feedlot'),
  intensive('intensive', 'Intensive'),
  semiIntensive('semi_intensive', 'Semi-intensive'),
  extensive('extensive', 'Extensive');

  const ProductionSystem(this.value, this.label);
  final String value;
  final String label;

  /// Turns a stored string back into an enum. Falls back to extensive
  /// if the stored value is missing or unrecognised, so one bad
  /// document can never crash the farms list.
  static ProductionSystem fromValue(String? v) {
    return ProductionSystem.values.firstWhere(
      (p) => p.value == v,
      orElse: () => ProductionSystem.extensive,
    );
  }
}

/// One registered farm. Farms are a registry: created once, then
/// referenced by every evaluation.
class Farm {
  const Farm({
    required this.id,
    required this.name,
    required this.county,
    required this.subCounty,
    required this.locationArea,
    required this.ownerManager,
    required this.contactPhone,
    required this.productionSystem,
    required this.createdBy,
    this.createdByName = '',
    this.createdAt,
  });

  /// Firestore document id. Empty string for a farm not yet saved.
  final String id;
  final String name;
  final String county;
  final String subCounty;

  /// Village or locality — finer than subcounty, free text.
  final String locationArea;

  final String ownerManager;

  /// Kept as a String so the leading zero survives (0722..., not 722...).
  final String contactPhone;

  final ProductionSystem productionSystem;

  /// uid of the evaluator who registered this farm.
  final String createdBy;

  /// Name of the registering evaluator, denormalised at write time.
  /// Empty on farms registered before this field existed — always
  /// render through [createdByLabel], never raw.
  final String createdByName;

  /// Null for a few milliseconds after creation, while the server
  /// timestamp is still resolving.
  final DateTime? createdAt;

  /// "Nandi · Aldai" — for list rows and detail headers.
  String get locationLabel =>
      subCounty.isEmpty ? county : '$county · $subCounty';

  /// Never blank: legacy farms show a dash rather than an empty gap.
  String get createdByLabel =>
      createdByName.trim().isEmpty ? '—' : createdByName;

  /// Firestore document -> Farm. The ONLY place that reads these keys.
  factory Farm.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Farm(
      id: doc.id,
      name: d['name'] as String? ?? '',
      county: d['county'] as String? ?? '',
      subCounty: d['sub_county'] as String? ?? '',
      locationArea: d['location_area'] as String? ?? '',
      ownerManager: d['owner_manager'] as String? ?? '',
      contactPhone: d['contact_phone'] as String? ?? '',
      productionSystem:
          ProductionSystem.fromValue(d['production_system'] as String?),
      createdBy: d['created_by'] as String? ?? '',
      // Nullable on purpose: legacy docs predate this field, and a
      // non-nullable cast here would break the WHOLE farms stream.
      createdByName: d['created_by_name'] as String? ?? '',
      // Firestore hands back a Timestamp, not a DateTime.
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Farm -> Firestore document. The ONLY place that writes these keys.
  /// created_at is set by the server, so it is not included here.
  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'name_lower': name.trim().toLowerCase(),
        'county': county.trim(),
        'sub_county': subCounty.trim(),
        'location_area': locationArea.trim(),
        'owner_manager': ownerManager.trim(),
        'contact_phone': contactPhone.replaceAll(RegExp(r'\s+'), ''),
        'production_system': productionSystem.value,
        'created_by': createdBy,
        'created_by_name': createdByName.trim(),
      };
}