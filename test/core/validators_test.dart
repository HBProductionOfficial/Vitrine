import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/core/validation/validators.dart';

void main() {
  group('login fields', () {
    test('username and password are required', () {
      expect(validateLoginUsername(''), FieldError.usernameRequired);
      expect(validateLoginUsername('   '), FieldError.usernameRequired);
      expect(validateLoginUsername('emilys'), isNull);
      expect(validateLoginPassword(''), FieldError.passwordRequired);
      expect(validateLoginPassword('x'), isNull);
    });

    test('a password of spaces still counts as typed', () {
      expect(validateLoginPassword('   '), isNull);
    });
  });

  group('sign-up fields', () {
    test('email', () {
      expect(validateEmail(''), FieldError.required);
      expect(validateEmail('emily'), FieldError.invalidEmail);
      expect(validateEmail('emily@mail'), FieldError.invalidEmail);
      expect(validateEmail(' emily@mail.com '), isNull);
    });

    test('username is 3 to 20 letters, digits or underscores', () {
      expect(validateNewUsername('ab'), FieldError.invalidUsername);
      expect(validateNewUsername('emily johnson'), FieldError.invalidUsername);
      expect(validateNewUsername('emily_j'), isNull);
      expect(validateNewUsername('a' * 21), FieldError.invalidUsername);
    });

    test('password needs 8 characters, a digit and a capital', () {
      expect(validateNewPassword('short1A'), FieldError.weakPassword);
      expect(validateNewPassword('longenough1'), FieldError.weakPassword);
      expect(validateNewPassword('LongEnough'), FieldError.weakPassword);
      expect(validateNewPassword('LongEnough1'), isNull);
    });

    test('repeat password must match', () {
      expect(validateRepeatPassword('', 'Secret123'), FieldError.required);
      expect(validateRepeatPassword('Secret12', 'Secret123'), FieldError.passwordsDontMatch);
      expect(validateRepeatPassword('Secret123', 'Secret123'), isNull);
    });
  });

  group('password strength', () {
    test('empty and very short passwords', () {
      expect(passwordStrength(''), PasswordStrength.empty);
      expect(passwordStrength('aB1!'), PasswordStrength.weak);
    });

    test('grows with length and variety', () {
      expect(passwordStrength('abcdefgh'), PasswordStrength.weak);
      expect(passwordStrength('abcdefgh1'), PasswordStrength.fair);
      expect(passwordStrength('Abcdefgh1'), PasswordStrength.good);
      expect(passwordStrength('Abcdefgh1234!'), PasswordStrength.strong);
    });
  });
}
