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