import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// What the sign-in button should call itself. Android's BiometricPrompt
/// decides between face and fingerprint on its own, so when the platform only
/// reports "strong/weak" we can't promise either and use [generic].
enum BiometricKind { none, face, fingerprint, generic }

enum BiometricFailure { notAvailable, notEnrolled, notSetUp, canceled, lockedOut, failed }

class BiometricException implements Exception {
  const BiometricException(this.reason);

  final BiometricFailure reason;

  @override
  String toString() => 'BiometricException($reason)';
}

@immutable
class BiometricSupport {
  const BiometricSupport(this.kind, {required this.enrolled});

  static const unavailable = BiometricSupport(BiometricKind.none, enrolled: false);

  /// [BiometricKind.none] means there's no sensor at all.
  final BiometricKind kind;

  /// False when the sensor exists but the user hasn't added a fingerprint or
  /// face (or has no screen lock), so authenticating can't succeed yet.
  final bool enrolled;
}

abstract class BiometricService {
  Future<BiometricSupport> check();

  /// Completes normally on success, throws [BiometricException] otherwise.
  Future<void> authenticate(String reason);
}

class LocalBiometricService implements BiometricService {
  LocalBiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricSupport> check() async {
    if (kIsWeb) return BiometricSupport.unavailable;
    try {
      if (!await _auth.canCheckBiometrics) return BiometricSupport.unavailable;
      final types = await _auth.getAvailableBiometrics();
      final enrolled = types.isNotEmpty && await _auth.isDeviceSupported();
      // Face wins when the platform names it (iPhones with Face ID). Android
      // only reports strong/weak classes, so it gets the generic label.
      final kind = types.contains(BiometricType.face)
          ? BiometricKind.face
          : types.contains(BiometricType.fingerprint)
              ? BiometricKind.fingerprint
              : BiometricKind.generic;
      return BiometricSupport(kind, enrolled: enrolled);
    } on LocalAuthException {
      return BiometricSupport.unavailable;
    }
  }

  @override
  Future<void> authenticate(String reason) async {
    final bool ok;
    try {
      ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      throw BiometricException(mapFailure(e.code));
    }
    if (!ok) throw const BiometricException(BiometricFailure.failed);
  }

  @visibleForTesting
  static BiometricFailure mapFailure(LocalAuthExceptionCode code) {
    return switch (code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout ||
      LocalAuthExceptionCode.userRequestedFallback =>
        BiometricFailure.canceled,
      LocalAuthExceptionCode.noBiometricsEnrolled || LocalAuthExceptionCode.noCredentialsSet => BiometricFailure.notEnrolled,
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
        BiometricFailure.notAvailable,
      LocalAuthExceptionCode.temporaryLockout || LocalAuthExceptionCode.biometricLockout => BiometricFailure.lockedOut,
      _ => BiometricFailure.failed,
    };
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) => LocalBiometricService());
