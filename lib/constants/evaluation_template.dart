import '../models/evaluation.dart';

/// One checklist question. `id` is what gets stored in the answers map,
/// so it must never change once evaluations exist — edit `text` freely,
/// but leave ids alone.
class ChecklistQuestion {
  const ChecklistQuestion(this.id, this.text);
  final String id;
  final String text;
}

/// Everything that makes one checklist section different from another.
/// Four sections share a single screen; only this data differs.
class SectionTemplate {
  const SectionTemplate({
    required this.key,
    required this.questions,
    this.positiveLabel = 'Yes',
    this.negativeLabel = 'No',
  });

  final SectionKey key;
  final List<ChecklistQuestion> questions;
  final String positiveLabel;
  final String negativeLabel;
}

/// DRAFT wording taken from the FCL beef evaluation template.
/// Confirm against the paper form before the pilot — changing the text
/// later is free, but changing the ids after data exists is not.
class EvaluationTemplate {
  EvaluationTemplate._();

  static const feeding = SectionTemplate(
    key: SectionKey.feeding,
    questions: [
      ChecklistQuestion('feed_plan', 'Documented feeding plan in place'),
      ChecklistQuestion(
          'ration_stage', 'Ration matches production stage'),
      ChecklistQuestion(
          'minerals', 'Minerals and salt licks provided'),
      ChecklistQuestion('water', 'Clean water always available'),
      ChecklistQuestion(
          'dry_season', 'Dry season feeding strategy in place'),
    ],
  );

  static const feedQuality = SectionTemplate(
    key: SectionKey.feedQuality,
    positiveLabel: 'Adequate',
    negativeLabel: 'Inadequate',
    questions: [
      ChecklistQuestion('forage', 'Forage quality'),
      ChecklistQuestion('concentrate', 'Concentrate quality'),
      ChecklistQuestion('storage', 'Feed storage conditions'),
      ChecklistQuestion('hygiene', 'Feed hygiene and spoilage control'),
      ChecklistQuestion('consistency', 'Consistency of feed supply'),
    ],
  );

  static const biosecurity = SectionTemplate(
    key: SectionKey.biosecurity,
    questions: [
      ChecklistQuestion('access', 'Farm access is restricted'),
      ChecklistQuestion(
          'footbath', 'Footbath or visitor record in use'),
      ChecklistQuestion(
          'quarantine', 'New animals are quarantined'),
      ChecklistQuestion('deworming', 'Routine deworming programme'),
      ChecklistQuestion(
          'isolation', 'Sick animals are isolated promptly'),
    ],
  );

  static const housing = SectionTemplate(
    key: SectionKey.housing,
    questions: [
      ChecklistQuestion('space', 'Adequate space per animal'),
      ChecklistQuestion('bedding', 'Clean, dry bedding or flooring'),
      ChecklistQuestion('ventilation', 'Ventilation is adequate'),
      ChecklistQuestion(
          'shade', 'Shade and weather protection provided'),
      ChecklistQuestion(
          'handling', 'Handling facilities are safe and usable'),
    ],
  );

  /// Performance monitoring: four yes/no practices, then the numbers.
  static const performanceChecks = [
    ChecklistQuestion('scale', 'Weighing scale available'),
    ChecklistQuestion('schedule', 'Regular weighing schedule kept'),
    ChecklistQuestion('adg_calc', 'Average daily gain is calculated'),
    ChecklistQuestion(
        'perf_records', 'Performance records are maintained'),
  ];

  /// id -> (label, unit). Optional: a farm that does not weigh cannot
  /// report a weight, and a blank is more honest than a guess.
  static const performanceKpis = <String, List<String>>{
    'weaning_weight': ['Weaning weight', 'kg'],
    'adg': ['Average daily gain', 'kg/day'],
    'slaughter_weight': ['Slaughter weight', 'kg'],
    'mortality_pct': ['Mortality rate', '%'],
  };

  /// Record keeping: tick every record type the farm actually keeps.
  static const recordTypes = [
    ChecklistQuestion('breeding', 'Breeding records'),
    ChecklistQuestion('health', 'Health and treatment records'),
    ChecklistQuestion('feed', 'Feed records'),
    ChecklistQuestion('financial', 'Financial records'),
    ChecklistQuestion('mortality', 'Mortality records'),
  ];

  /// The diseases FCL asks about by default. An EO can add others on
  /// the vaccination screen; these are just the starting rows.
  static const defaultVaccinations = [
    'FMD',
    'LSD',
    'Black quarter / anthrax',
    'Brucellosis',
  ];

  /// Stored value -> label. 'not_done' and 'unknown' are real answers,
  /// not missing data, so an EO always has an honest option.
  static const vaccinationFrequencies = <String, String>{
    'annually': 'Annually',
    'biannually': 'Twice a year',
    'on_arrival': 'On arrival only',
    'rarely': 'Rarely',
    'not_done': 'Not done',
    'unknown': 'Farmer unsure',
  };

  /// Lookup used by the hub when opening a checklist section.
  static SectionTemplate? forKey(SectionKey key) {
    switch (key) {
      case SectionKey.feeding:
        return feeding;
      case SectionKey.feedQuality:
        return feedQuality;
      case SectionKey.biosecurity:
        return biosecurity;
      case SectionKey.housing:
        return housing;
      // Vaccination, performance and records have their own screens.
      default:
        return null;
    }
  }
}