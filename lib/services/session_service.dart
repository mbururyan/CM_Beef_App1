import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// The signed-in evaluator, as this device knows them.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.role,
  });

  final String uid;
  final String fullName;
  final String username;
  final String role;

  /// "RT" — for the drawer avatar.
  String get initials => fullName
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  static const unknown = UserProfile(
    uid: '',
    fullName: 'Evaluator',
    username: '',
    role: 'evaluator',
  );
}

/// Holds the signed-in EO's profile in memory for the life of the
/// session.
///
/// Why this exists: every evaluation and every farm we write carries a
/// denormalised eo_name / created_by_name. Reading users/{uid} at write
/// time would stamp a blank name whenever the read misses — precisely
/// the offline case the denormalisation exists to survive. So we load
/// the profile ONCE at sign-in, hold it, and stamp from memory.
class SessionService {
  SessionService._();
  static final instance = SessionService._();

  UserProfile? _profile;

  /// Never null at call sites — falls back rather than crashing a write.
  UserProfile get profile => _profile ?? UserProfile.unknown;

  bool get isLoaded => _profile != null;

  /// Loads the profile for the signed-in user. Call after login and on
  /// splash before entering the shell.
  ///
  /// Firestore serves this from its local cache when offline, so a
  /// returning EO keeps their name with no signal. get() is used rather
  /// than a stream because a profile changes about once a year.
  Future<void> load() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final d = doc.data();
      if (d == null) return;

      _profile = UserProfile(
        uid: user.uid,
        fullName: d['full_name'] as String? ?? 'Evaluator',
        username: d['username'] as String? ?? '',
        role: d['role'] as String? ?? 'evaluator',
      );
    } catch (_) {
      // Offline with nothing cached: leave null, callers get the
      // fallback. Better a generic name than a crash mid-visit.
    }
  }

  /// Wipe on logout so the next EO on this phone never inherits a name.
  void clear() => _profile = null;
}