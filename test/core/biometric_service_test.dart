import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitrine/src/core/biometrics/biometric_service.dart';

class MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuth auth;
  late LocalBiometricService service;

  void phone({required bool canCheck, List<BiometricType> types = const [], bool supported = true}) {
    when(() => auth.canCheckBiometrics).thenAnswer((_) async => canCheck);
    when(() => auth.getAvailableBiometrics()).thenAnswer((_) async => types);
    when(() => auth.isDeviceSupported()).thenAnswer((_) async => supported);
  }

  setUp(() {
    auth = MockLocalAuth();
    service = LocalBiometricService(auth);
  });

  group('which kind to show', () {
    test('face wins over fingerprint when both are there', () async {
      phone(canCheck: true, types: [BiometricType.fingerprint, BiometricType.face]);
      final support = await service.check();
      expect(support.kind, BiometricKind.face);
      expect(support.enrolled, isTrue);
    });

    test('fingerprint only', () async {
      phone(canCheck: true, types: [BiometricType.fingerprint]);
      expect((await service.check()).kind, BiometricKind.fingerprint);
    });

    test('Android strength classes get the generic label', () async {
      phone(canCheck: true, types: [BiometricType.strong]);
      expect((await service.check()).kind, BiometricKind.generic);
    });

    test('a sensor with nothing enrolled is shown but not enrolled', () async {
      phone(canCheck: true, supported: false);
      final support = await service.check();
      expect(support.kind, BiometricKind.generic);
      expect(support.enrolled, isFalse);
    });

    test('no sensor', () async {
      phone(canCheck: false);
      expect((await service.check()).kind, BiometricKind.none);
    });
  });

  test('platform errors map to the messages the UI knows', () {
    expect(LocalBiometricService.mapFailure(LocalAuthExceptionCode.userCanceled), BiometricFailure.canceled);
    expect(LocalBiometricService.mapFailure(LocalAuthExceptionCode.noBiometricsEnrolled), BiometricFailure.notEnrolled);
    expect(LocalBiometricService.mapFailure(LocalAuthExceptionCode.noCredentialsSet), BiometricFailure.notEnrolled);
    expect(LocalBiometricService.mapFailure(LocalAuthExceptionCode.biometricLockout), BiometricFailure.lockedOut);
    expect(LocalBiometricService.mapFailure(LocalAuthExceptionCode.noBiometricHardware), BiometricFailure.notAvailable);
  });
}
