/// Common string validators used across auth + profile features.
///
/// Pure functions — no async, no I/O — so they're trivially testable.
class Validators {
  const Validators._();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns `null` if [value] is a valid email, otherwise an error
  /// message. Designed for use as a `FormField<String>.validator`.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'At least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Add a number';
    return null;
  }

  static String? minLength(String? value, int min, {String? label}) {
    if (value == null || value.length < min) {
      return '${label ?? 'This field'} must be at least $min characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
