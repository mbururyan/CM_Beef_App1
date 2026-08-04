import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/evaluation.dart';
import '../models/farm.dart';
import 'auth_service.dart';
import 'session_service.dart';

/// Everything that touches the evaluations collection.
class EvaluationService {
  EvaluationService._();
  static final instance = EvaluationService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _evals =>
      _db.collection('evaluations');

  /// Opens a draft visit and returns its id.
  ///
  /// The id is generated on the device, so this works with no signal and
  /// the id never changes — every section saved afterwards points at the
  /// right document even if nothing has reached the server yet.
  ///
  /// Farm details are copied onto the visit deliberately: the farmer's
  /// PDF and the admin filters must work without a second lookup.
  String createDraft({
    required Farm farm,
    required DateTime evaluationDate,
    required int breedingCows,
    required int bulls,
    required int calves,
    required int growersSteers,
  }) {
    final uid = AuthService.instance.currentUser!.uid;
    // From the in-memory session, never a Firestore read — offline this
    // is the only source that gives the right name.
    final eoName = SessionService.instance.profile.fullName;

    final ref = _evals.doc();
    ref.set({
      'farm_id': farm.id,
      'farm_name': farm.name,
      'county': farm.county,
      'sub_county': farm.subCounty,
      'eo_id': uid,
      'eo_name': eoName,
      'evaluation_date': Timestamp.fromDate(evaluationDate),
      'breeding_cows': breedingCows,
      'bulls': bulls,
      'calves': calves,
      'growers_steers': growersSteers,
      'sections': <String, dynamic>{},
      'vaccinations': <Map<String, dynamic>>[],
      'key_strengths': <String>[],
      'areas_improvement': <String>[],
      'recommendations': '',
      'total_score': 0,
      'rating': Rating.poor.value,
      'status': 'draft',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  /// Saves one section. Sections are stored as a MAP keyed by section
  /// name rather than a list, so this touches exactly one field —
  /// Firestore cannot update a single element of an array by key.
  void saveSection(String evalId, EvaluationSection section) {
    _evals.doc(evalId).update({
      'sections.${section.key.value}': section.toMap(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// The vaccination screen is edited as a whole, so its list is
  /// replaced wholesale.
  void saveVaccinations(
      String evalId, List<VaccinationRecord> records) {
    _evals.doc(evalId).update({
      'vaccinations': records.map((r) => r.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  void saveSummary(
    String evalId, {
    required List<String> keyStrengths,
    required List<String> areasImprovement,
    required String recommendations,
  }) {
    _evals.doc(evalId).update({
      'key_strengths': keyStrengths,
      'areas_improvement': areasImprovement,
      'recommendations': recommendations.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Finalises the visit. Score and rating are computed here from the
  /// section scores — never typed by the evaluator, so the arithmetic
  /// cannot drift.
  Future<void> submit(Evaluation evaluation) async {
    final total = evaluation.totalScore;
    _evals.doc(evaluation.id).update({
      'total_score': total,
      'rating': Rating.fromScore(total).value,
      'status': 'submitted',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Live single visit — the wizard watches this so every screen sees
  /// the same saved state.
  Stream<Evaluation?> watch(String evalId) => _evals
      .doc(evalId)
      .snapshots()
      .map((doc) => doc.exists ? Evaluation.fromDoc(doc) : null);

  /// This evaluator's unfinished visits, newest first. Feeds the Home
  /// drafts section.
  Stream<List<Evaluation>> myDrafts() {
    final uid = AuthService.instance.currentUser!.uid;
    return _evals
        .where('eo_id', isEqualTo: uid)
        .where('status', isEqualTo: 'draft')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Evaluation.fromDoc).toList());
  }

  /// This evaluator's completed visits, newest first. Feeds Home's last
  /// visit row and, later, My Reports.
  Stream<List<Evaluation>> mySubmitted({int limit = 20}) {
    final uid = AuthService.instance.currentUser!.uid;
    return _evals
        .where('eo_id', isEqualTo: uid)
        .where('status', isEqualTo: 'submitted')
        .orderBy('evaluation_date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Evaluation.fromDoc).toList());
  }

  /// Every visit to one farm, by any evaluator — the farm detail
  /// history. Not scoped to the signed-in EO on purpose: a farm's
  /// history is the farm's, not one officer's.
  Stream<List<Evaluation>> byFarm(String farmId) => _evals
      .where('farm_id', isEqualTo: farmId)
      .orderBy('evaluation_date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Evaluation.fromDoc).toList());

  /// Any open draft for this farm by this evaluator — powers the draft
  /// guard on visit setup, so an EO resumes instead of duplicating.
  Future<Evaluation?> openDraftForFarm(String farmId) async {
    final uid = AuthService.instance.currentUser!.uid;
    final snap = await _evals
        .where('eo_id', isEqualTo: uid)
        .where('farm_id', isEqualTo: farmId)
        .where('status', isEqualTo: 'draft')
        .limit(1)
        .get();
    return snap.docs.isEmpty
        ? null
        : Evaluation.fromDoc(snap.docs.first);
  }
}