/// Validation rules return an error code instead of a message, so they can
/// be unit tested and translated in the widget layer.
enum FieldError {
  required,
  usernameRequired,
  passwordRequired,
  invalidEmail,
  invalidUsername,
  weakPassword,
  passwordsDontMatch,
}

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
final _username = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

FieldError? validateRequired(String? value) =>
    (value == null || value.trim().isEmpty) ? FieldError.required : null;

FieldError? validateLoginUsername(String? value) =>
    (value == null || value.trim().isEmpty) ? FieldError.usernameRequired : null;

FieldError? validateLoginPassword(String? value) =>
    (value == null || value.isEmpty) ? FieldError.passwordRequired : null;

FieldError? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return FieldError.required;
  return _email.hasMatch(value.trim()) ? null : FieldError.invalidEmail;
}

FieldError? validateNewUsername(String? value) {
  if (value == null || value.trim().isEmpty) return FieldError.required;
  return _username.hasMatch(value.trim()) ? null : FieldError.invalidUsername;
}

FieldError? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return FieldError.required;
  final strongEnough = value.length >= 8 && value.contains(RegExp(r'[0-9]')) && value.contains(RegExp(r'[A-Z]'));
  return strongEnough ? null : FieldError.weakPassword;
}

FieldError? validateRepeatPassword(String? value, String original) {
  if (value == null || value.isEmpty) return FieldError.required;
  return value == original ? null : FieldError.passwordsDontMatch;
}

enum PasswordStrength { empty, weak, fair, good, strong }

/// Rough score for the meter under the sign-up password field. It rewards
/// length first, then variety of character types.
PasswordStrength passwordStrength(String value) {
  if (value.isEmpty) return PasswordStrength.empty;
  var score = 0;
  if (value.length >= 8) score++;
  if (value.length >= 12) score++;
  if (value.contains(RegExp(r'[a-z]')) && value.contains(RegExp(r'[A-Z]'))) score++;
  if (value.contains(RegExp(r'[0-9]'))) score++;
  if (value.contains(RegExp(r'[^a-zA-Z0-9]'))) score++;
  if (value.length < 6) return PasswordStrength.weak;
  return switch (score) {
    <= 1 => PasswordStrength.weak,
    2 => PasswordStrength.fair,
    3 || 4 => PasswordStrength.good,
    _ => PasswordStrength.strong,
  };
}
