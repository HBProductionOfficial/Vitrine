import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitrine/src/core/biometrics/biometric_service.dart';

class MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuth auth;
  late LocalBiometricService service;
  var sensors = <String>{};

  void phone({required bool canCheck, List<BiometricType> types = const [], bool supported = true}) {
    when(() => auth.canCheckBiometrics).thenAnswer((_) async => canCheck);
    when(() => auth.getAvailableBiometrics()).thenAnswer((_) async => types);
    when(() => auth.isDeviceSupported()).thenAnswer((_) async => supported);
  }

  setUp(() {
    auth = MockLocalAuth();
    sensors = {};
    service = LocalBiometricService(auth: auth, sensors: () async => sensors);
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

    test('Android with both sensors offers face or fingerprint', () async {
      phone(canCheck: true, types: [BiometricType.weak, BiometricType.strong]);
      sensors = {'face', 'fingerprint'};
      expect((await service.check()).kind, BiometricKind.faceOrFingerprint);
    });

    test('Android with only one sensor names it', () async {
      phone(canCheck: true, types: [BiometricType.strong]);
      sensors = {'fingerprint'};
      expect((await service.check()).kind, BiometricKind.fingerprint);
      sensors = {'face'};
      expect((await service.check()).kind, BiometricKind.face);
    });

    test('anything else, like an iris scanner, gets the generic label', () async {
      phone(canCheck: true, types: [BiometricType.strong]);
      sensors = {'iris'};
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
