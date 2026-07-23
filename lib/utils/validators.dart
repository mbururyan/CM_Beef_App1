/// Shared form validators — the spec's validation rules in one place.
/// Each returns an error message, or null when the value passes.
class Validators {
  Validators._();

  static String? required(String? v, String fieldName) =>
      (v == null || v.trim().isEmpty) ? '$fieldName cannot be blank' : null;

  /// Min 4 chars; lowercase letters, numbers and dots only.
  /// (Uniqueness is checked against Firestore in increment four.)
  static String? username(String? v) {
    final blank = required(v, 'Username');
    if (blank != null) return blank;
    final value = v!.trim();
    if (value.length < 4) return 'Username must be at least 4 characters';
    if (!RegExp(r'^[a-z0-9.]+$').hasMatch(value)) {
      return 'Lowercase letters, numbers and dots only';
    }
    return null;
  }

  static String? email(String? v) {
    final blank = required(v, 'Email');
    if (blank != null) return blank;
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v!.trim());
    return ok ? null : 'Enter a valid email address';
  }

  /// Kenyan formats: 07xx/01xx + 8 digits, or +254 equivalent.
  static String? kenyanPhone(String? v) {
    final blank = required(v, 'Phone');
    if (blank != null) return blank;
    final digits = v!.replaceAll(RegExp(r'\s+'), '');
    final ok = RegExp(r'^(?:\+254(7|1)\d{8}|0(7|1)\d{8})$').hasMatch(digits);
    return ok ? null : 'Enter a valid Kenyan phone number';
  }

  /// Min 8 characters, at least one number.
  static String? password(String? v) {
    final blank = required(v, 'Password');
    if (blank != null) return blank;
    if (v!.length < 8) return 'At least 8 characters';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    final blank = required(v, 'Confirm password');
    if (blank != null) return blank;
    return v == original ? null : 'Passwords do not match';
  }

  /// 0 = empty, 1 = weak, 2 = medium, 3 = strong. Drives the meter bars.
  static int passwordStrength(String v) {
    if (v.isEmpty) return 0;
    var score = 1;
    if (v.length >= 8 && RegExp(r'\d').hasMatch(v)) score = 2;
    if (v.length >= 12 &&
        RegExp(r'[A-Z]').hasMatch(v) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      score = 3;
    }
    return score;
  }
}