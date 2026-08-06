import 'package:cloud_firestore/cloud_firestore.dart';

/// The seven scored sections of the FCL beef evaluation.
/// `value` is what Firestore stores; `label` is what the UI shows.
enum SectionKey {
  feeding('feeding', 'Feeding and nutrition'),
  feedQuality('feed_quality', 'Feed quality'),
  biosecurity('biosecurity', 'Biosecurity and disease control'),
  vaccination('vaccination', 'Vaccination'),
  housing('housing', 'Housing and welfare'),
  performance('performance', 'Performance monitoring'),
  records('records', 'Record keeping');

  const SectionKey(this.value, this.label);
  final String value;
  final String label;

  static SectionKey fromValue(String v) => SectionKey.values.firstWhere(
        (s) => s.value == v,
        orElse: () => SectionKey.feeding,
      );
}

/// Overall verdict, derived from the total score — never stored by hand.
/// Bands are PROVISIONAL: confirm against FCL's supplier threshold.
enum Rating {
  poor('poor', 'Poor'),
  fair('fair', 'Fair'),
  good('good', 'Good'),
  excellent('excellent', 'Excellent');

  const Rating(this.value, this.label);
  final String value;
  final String label;

  /// Out of a maximum of 35 (7 sections x 5).
  static Rating fromScore(int total) {
    if (total >= 30) return Rating.excellent;
    if (total >= 24) return Rating.good;
    if (total >= 17) return Rating.fair;
    return Rating.poor;
  }

  static Rating fromValue(String? v) => Rating.values.firstWhere(
        (r) => r.value == v,
        orElse: () => Rating.poor,
      );
}

/// One completed section: the checklist answers, the evaluator's note,
/// and the 1-5 score.
class EvaluationSection {
  const EvaluationSection({
    required this.key,
    required this.answers,
    required this.comment,
    required this.score,
  });

  final SectionKey key;

  /// Question id -> answer. Kept as a free-form map on purpose: adding a
  /// sixth checklist item later is a form change, never a migration.
  /// Performance also carries its KPI numbers in here.
  final Map<String, dynamic> answers;

  /// Internal field note. NOT shown on the farmer's PDF.
  final String comment;

  /// 1-5.
  final int score;

  factory EvaluationSection.fromMap(String key, Map<String, dynamic> m) {
    return EvaluationSection(
      key: SectionKey.fromValue(key),
      answers: Map<String, dynamic>.from(m['answers'] as Map? ?? {}),
      comment: m['comment'] as String? ?? '',
      score: (m['score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'answers': answers,
        'comment': comment.trim(),
        'score': score,
      };
}

/// One disease row in the vaccination section.
class VaccinationRecord {
  const VaccinationRecord({
    required this.disease,
    required this.frequency,
    this.lastAdministered,
    this.dateUnknown = false,
    this.recordsAvailable = false,
  });

  final String disease;

  /// annually | biannually | on_arrival | rarely | not_done | unknown
  final String frequency;

  final DateTime? lastAdministered;

  /// True when the farmer could not recall the date — an honest boolean
  /// instead of a guessed date.
  final bool dateUnknown;

  final bool recordsAvailable;

  factory VaccinationRecord.fromMap(Map<String, dynamic> m) {
    return VaccinationRecord(
      disease: m['disease'] as String? ?? '',
      frequency: m['frequency'] as String? ?? 'unknown',
      lastAdministered:
          (m['last_administered'] as Timestamp?)?.toDate(),
      dateUnknown: m['date_unknown'] as bool? ?? false,
      recordsAvailable: m['records_available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'disease': disease.trim(),
        'frequency': frequency,
        'last_administered': lastAdministered == null
            ? null
            : Timestamp.fromDate(lastAdministered!),
        'date_unknown': dateUnknown,
        'records_available': recordsAvailable,
      };
}

/// A single farm visit. One Firestore document, written atomically so an
/// offline visit either lands whole or retries whole.
class Evaluation {
  const Evaluation({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.county,
    required this.subCounty,
    required this.eoId,
    required this.eoName,
    required this.evaluationDate,
    required this.breedingCows,
    required this.bulls,
    required this.calves,
    required this.growersSteers,
    required this.sections,
    required this.vaccinations,
    required this.keyStrengths,
    required this.areasImprovement,
    required this.recommendations,
    required this.status,
    this.createdAt,
    this.pendingSync = false,
  });

  final String id;

  /// Denormalised from the farm so lists, filters and the farmer's PDF
  /// all work without a second lookup — and work offline.
  final String farmId;
  final String farmName;
  final String county;
  final String subCounty;

  /// Who did THIS evaluation. Independent of who registered the farm.
  final String eoId;
  final String eoName;

  final DateTime evaluationDate;

  final int breedingCows;
  final int bulls;
  final int calves;
  final int growersSteers;

  /// Keyed by section value, so one section can be saved on its own.
  final Map<SectionKey, EvaluationSection> sections;

  final List<VaccinationRecord> vaccinations;

  final List<String> keyStrengths;
  final List<String> areasImprovement;
  final String recommendations;

  /// 'draft' or 'submitted'.
  final String status;

  final DateTime? createdAt;

  /// True while this device holds the visit but the server has not
  /// confirmed it. Comes from Firestore's own document metadata, not
  /// from guessing at connectivity.
  final bool pendingSync;

  // --- Derived values: never stored by hand ---

  /// Total herd — computed, so it can never disagree with its parts.
  int get totalHerd => breedingCows + bulls + calves + growersSteers;

  /// Sum of the section scores. Partial while the wizard is in progress.
  int get totalScore =>
      sections.values.fold(0, (sum, s) => sum + s.score);

  Rating get rating => Rating.fromScore(totalScore);

  int get completedSections => sections.length;

  bool get isComplete => completedSections == SectionKey.values.length;

  bool get isDraft => status == 'draft';

  /// "4/7"
  String get progressLabel =>
      '$completedSections/${SectionKey.values.length}';

  factory Evaluation.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    final rawSections = Map<String, dynamic>.from(
        d['sections'] as Map? ?? const {});
    final sections = <SectionKey, EvaluationSection>{};
    rawSections.forEach((k, v) {
      final section = EvaluationSection.fromMap(
          k, Map<String, dynamic>.from(v as Map));
      sections[section.key] = section;
    });

    final rawVacc = (d['vaccinations'] as List? ?? const []);

    return Evaluation(
      id: doc.id,
      farmId: d['farm_id'] as String? ?? '',
      farmName: d['farm_name'] as String? ?? '',
      county: d['county'] as String? ?? '',
      subCounty: d['sub_county'] as String? ?? '',
      eoId: d['eo_id'] as String? ?? '',
      eoName: d['eo_name'] as String? ?? '',
      evaluationDate:
          (d['evaluation_date'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      breedingCows: (d['breeding_cows'] as num?)?.toInt() ?? 0,
      bulls: (d['bulls'] as num?)?.toInt() ?? 0,
      calves: (d['calves'] as num?)?.toInt() ?? 0,
      growersSteers: (d['growers_steers'] as num?)?.toInt() ?? 0,
      sections: sections,
      vaccinations: rawVacc
          .map((v) => VaccinationRecord.fromMap(
              Map<String, dynamic>.from(v as Map)))
          .toList(),
      keyStrengths:
          List<String>.from(d['key_strengths'] as List? ?? const []),
      areasImprovement: List<String>.from(
          d['areas_improvement'] as List? ?? const []),
      recommendations: d['recommendations'] as String? ?? '',
      status: d['status'] as String? ?? 'draft',
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
      pendingSync: doc.metadata.hasPendingWrites,
    );
  }
}