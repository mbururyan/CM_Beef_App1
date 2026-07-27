import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thrown with a message safe to show directly in a snackbar.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// All Firebase Auth + Firestore account logic lives here.
/// Screens call these methods and show the result; they never
/// talk to Firebase directly.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Creates the Auth account, then the users/{uid} profile,
  /// then claims usernames/{username}. Throws AuthException with a
  /// friendly message on any failure.
  Future<void> signUp({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final uname = username.trim().toLowerCase();

    // 1. Uniqueness check (fast feedback; the create rule is the
    //    real enforcement if two people race for the same name).
    final existing = await _db.collection('usernames').doc(uname).get();
    if (existing.exists) {
      throw AuthException('That username is already taken');
    }

    // 2. Create the Firebase Auth account.
    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }

    final uid = cred.user!.uid;

    // 3. Profile + username claim in one atomic batch: both land
    //    or neither does.
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(uid), {
      'full_name': fullName.trim(),
      'username': uname,
      'email': email.trim(),
      'phone': phone.replaceAll(RegExp(r'\s+'), ''),
      'role': 'evaluator', // spec: every signup is an evaluator
      'active': true,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('usernames').doc(uname), {
      'email': email.trim(),
      'uid': uid,
    });

    try {
      await batch.commit();
    } catch (_) {
      // Racer lost the username between check and commit: roll back
      // the orphaned Auth account so the email can retry.
      await cred.user!.delete();
      throw AuthException('That username is already taken');
    }
  }

  /// Username -> email lookup, then Firebase sign-in.
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final uname = username.trim().toLowerCase();

    final doc = await _db.collection('usernames').doc(uname).get();
    if (!doc.exists) {
      throw AuthException('Invalid username or password');
    }
    final email = doc.data()!['email'] as String;

    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Maps Firebase error codes to messages fit for the screen.
  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'That email address is not valid';
      case 'weak-password':
        return 'Password is too weak';
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid username or password';
      case 'network-request-failed':
        return 'No connection — check your internet and try again';
      case 'too-many-requests':
        return 'Too many attempts — wait a moment and try again';
      default:
        return 'Something went wrong (${e.code})';
    }
  }
}