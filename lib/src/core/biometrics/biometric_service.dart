import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// What the sign-in button should call itself. [faceOrFingerprint] is a
/// phone with both sensors: Android's prompt takes whichever is set up, and
/// an app can't ask for one in particular. [generic] covers anything else,
/// such as an iris scanner.
enum BiometricKind { none, face, fingerprint, faceOrFingerprint, generic }

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
  LocalBiometricService({LocalAuthentication? auth, Future<Set<String>> Function()? sensors})
    : _auth = auth ?? LocalAuthentication(),
      _sensors = sensors ?? _androidSensors;

  final LocalAuthentication _auth;

  /// Sensor names from the system: "face", "fingerprint", "iris".
  final Future<Set<String>> Function() _sensors;

  @override
  Future<BiometricSupport> check() async {
    if (kIsWeb) return BiometricSupport.unavailable;
    try {
      if (!await _auth.canCheckBiometrics) return BiometricSupport.unavailable;
      final types = await _auth.getAvailableBiometrics();
      final enrolled = types.isNotEmpty && await _auth.isDeviceSupported();
      return BiometricSupport(await _kind(types), enrolled: enrolled);
    } on LocalAuthException {
      return BiometricSupport.unavailable;
    }
  }

  Future<BiometricKind> _kind(List<BiometricType> types) async {
    // iPhones say exactly what they have.
    if (types.contains(BiometricType.face)) return BiometricKind.face;
    if (types.contains(BiometricType.fingerprint)) return BiometricKind.fingerprint;
    // Android only reports strong or weak, so look at the sensors instead.
    final sensors = await _sensors();
    final face = sensors.contains('face');
    final fingerprint = sensors.contains('fingerprint');
    if (face && fingerprint) return BiometricKind.faceOrFingerprint;
    if (face) return BiometricKind.face;
    if (fingerprint) return BiometricKind.fingerprint;
    return BiometricKind.generic;
  }

  static Future<Set<String>> _androidSensors() async {
    if (defaultTargetPlatform != TargetPlatform.android) return const {};
    try {
      const channel = MethodChannel('vitrine/biometric_hardware');
      return {...?await channel.invokeListMethod<String>('sensors')};
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  @override
  Future<void> authenticate(String reason) async {
    final bool ok;
    try {
      ok = await _auth.authenticate(localizedReason: reason, biometricOnly: true, persistAcrossBackgrounding: true);
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
      LocalAuthExceptionCode.userRequestedFallback => BiometricFailure.canceled,
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noCredentialsSet => BiometricFailure.notEnrolled,
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable => BiometricFailure.notAvailable,
      LocalAuthExceptionCode.temporaryLockout || LocalAuthExceptionCode.biometricLockout => BiometricFailure.lockedOut,
      _ => BiometricFailure.failed,
    };
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) => LocalBiometricService());
