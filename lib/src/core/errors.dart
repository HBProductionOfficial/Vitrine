import 'package:vitrine/l10n/gen/app_localizations.dart';

import 'biometrics/biometric_service.dart';
import 'network/api_exception.dart';
import 'validation/validators.dart';

/// One place that turns failures into the sentence the user reads.
String describeError(Object error, AppLocalizations l10n) {
  if (error is ApiException) {
    return switch (error.kind) {
      ApiErrorKind.network => l10n.errorNetwork,
      ApiErrorKind.timeout => l10n.errorTimeout,
      ApiErrorKind.invalidCredentials => l10n.errorInvalidCredentials,
      ApiErrorKind.unauthorized => l10n.errorSessionExpired,
      ApiErrorKind.rateLimited => l10n.errorRateLimited,
      ApiErrorKind.server => l10n.errorServer,
      _ => l10n.errorUnknown,
    };
  }
  if (error is BiometricException) {
    return switch (error.reason) {
      BiometricFailure.notAvailable => l10n.bioNoHardware,
      BiometricFailure.notEnrolled => l10n.bioNotEnrolled,
      BiometricFailure.notSetUp => l10n.bioNotSetUp,
      BiometricFailure.canceled => l10n.bioCanceled,
      BiometricFailure.lockedOut => l10n.bioLockedOut,
      BiometricFailure.failed => l10n.bioFailed,
    };
  }
  return l10n.errorUnknown;
}

String describeFieldError(FieldError error, AppLocalizations l10n) {
  return switch (error) {
    FieldError.required => l10n.errorFieldRequired,
    FieldError.usernameRequired => l10n.errorUsernameRequired,
    FieldError.passwordRequired => l10n.errorPasswordRequired,
    FieldError.invalidEmail => l10n.errorEmailInvalid,
    FieldError.invalidUsername => l10n.errorUsernameInvalid,
    FieldError.weakPassword => l10n.errorPasswordWeak,
    FieldError.passwordsDontMatch => l10n.errorPasswordsDontMatch,
  };
}
