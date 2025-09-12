import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/core/biometrics/biometric_service.dart';
import 'package:vitrine/src/core/network/api_exception.dart';
import 'package:vitrine/src/core/network/token_holder.dart';
import 'package:vitrine/src/core/storage/preferences.dart';
import 'package:vitrine/src/core/storage/secure_store.dart';
import 'package:vitrine/src/features/auth/data/dummy_json_auth_repository.dart';
import 'package:vitrine/src/features/auth/domain/auth_repository.dart';
import 'package:vitrine/src/features/auth/domain/user.dart';
import 'package:vitrine/src/features/auth/presentation/auth_controller.dart';

class MockBiometrics extends Mock implements BiometricService {}

const _emily = User(id: 1, username: 'emilys', email: 'emily@x.test', firstName: 'Emily', lastName: 'Johnson');

class FakeAuthRepository implements AuthRepository {
  int refreshCalls = 0;
  bool refreshFails = false;

  @override
  Future<(User, AuthTokens)> login(String username, String password) async {
    if (username != 'emilys' || password != 'emilyspass') {
      throw const ApiException(ApiErrorKind.invalidCredentials, statusCode: 400);
    }
    return (_emily, const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'));
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCalls++;
    if (refreshFails) throw const ApiException(ApiErrorKind.unauthorized, statusCode: 401);
    return const AuthTokens(accessToken: 'access-2', refreshToken: 'refresh-2');
  }

  @override
  Future<User> currentUser() async => _emily;

  @override
  Future<int> signUp(SignUpRequest request) async => 209;

  @override
  Future<void> sendPasswordReset(String email) async {}
}

void main() {
  late MockBiometrics biometrics;
  late MemorySecureStore secure;
  late FakeAuthRepository repo;
  late SharedPreferences prefs;

  Future<ProviderContainer> start({Map<String, Object> savedPrefs = const {}, String? savedToken}) async {
    SharedPreferences.setMockInitialValues(savedPrefs);
    prefs = await SharedPreferences.getInstance();
    if (savedToken != null) await secure.write(AuthController.refreshTokenKey, savedToken);
    final container = ProviderContainer.test(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        secureStoreProvider.overrideWithValue(secure),
        biometricServiceProvider.overrideWithValue(biometrics),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    container.read(authControllerProvider);
    // build() restores the session in a microtask; let it finish.
    await pumpEventQueue();
    return container;
  }

  void sensor(BiometricKind kind, {bool enrolled = true}) {
    when(() => biometrics.check()).thenAnswer((_) async => BiometricSupport(kind, enrolled: enrolled));
  }

  setUp(() {
    biometrics = MockBiometrics();
    secure = MemorySecureStore();
    repo = FakeAuthRepository();
    sensor(BiometricKind.fingerprint);
  });

  test('starts signed out when nothing is saved', () async {
    final container = await start();
    final state = container.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).biometricKind, BiometricKind.fingerprint);
  });

  group('password sign-in', () {
    test('keeps the refresh token when "keep me signed in" is on', () async {
      final container = await start();
      await container.read(authControllerProvider.notifier).login('emilys', 'emilyspass', rememberMe: true);

      expect(container.read(authControllerProvider), isA<SignedIn>());
      expect(container.read(tokenHolderProvider).accessToken, 'access-1');
      expect(secure.values[AuthController.refreshTokenKey], 'refresh-1');
    });

    test('forgets the refresh token when it is off', () async {
      final container = await start();
      await container.read(authControllerProvider.notifier).login('emilys', 'emilyspass', rememberMe: false);

      expect(container.read(authControllerProvider), isA<SignedIn>());
      expect(secure.values, isEmpty);
    });

    test('wrong password throws and stays signed out', () async {
      final container = await start();
      final login = container.read(authControllerProvider.notifier).login('emilys', 'nope', rememberMe: true);

      await expectLater(
        login,
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.invalidCredentials)),
      );
      expect(container.read(authControllerProvider), isA<SignedOut>());
    });

    test('offers biometric unlock once, if the phone can do it', () async {
      final container = await start();
      await container.read(authControllerProvider.notifier).login('emilys', 'emilyspass', rememberMe: false);
      expect((container.read(authControllerProvider) as SignedIn).offerBiometrics, isTrue);
    });

    test('no offer when nothing is enrolled', () async {
      sensor(BiometricKind.fingerprint, enrolled: false);
      final container = await start();
      await container.read(authControllerProvider.notifier).login('emilys', 'emilyspass', rememberMe: false);
      expect((container.read(authControllerProvider) as SignedIn).offerBiometrics, isFalse);
    });
  });

  group('restoring a session', () {
    test('a remembered session signs straight back in', () async {
      final container = await start(savedPrefs: {'auth.rememberMe': true}, savedToken: 'refresh-1');

      expect(container.read(authControllerProvider), isA<SignedIn>());
      expect(repo.refreshCalls, 1);
      expect(secure.values[AuthController.refreshTokenKey], 'refresh-2');
    });

    test('an expired refresh token is dropped', () async {
      repo.refreshFails = true;
      final container = await start(savedPrefs: {'auth.rememberMe': true}, savedToken: 'refresh-1');

      expect(container.read(authControllerProvider), isA<SignedOut>());
      expect(secure.values, isEmpty);
    });

    test('with biometrics on, it waits for the fingerprint instead', () async {
      final container = await start(savedPrefs: {'auth.biometricEnabled': true}, savedToken: 'refresh-1');

      final state = container.read(authControllerProvider);
      expect(state, isA<SignedOut>());
      expect((state as SignedOut).biometricReady, isTrue);
      expect(repo.refreshCalls, 0);
    });
  });

  group('biometric unlock', () {
    Future<Object?> unlockError(ProviderContainer container) async {
      try {
        await container.read(authControllerProvider.notifier).unlockWithBiometrics('reason');
        return null;
      } catch (e) {
        return e;
      }
    }

    test('succeeds and resumes the saved session', () async {
      when(() => biometrics.authenticate(any())).thenAnswer((_) async {});
      final container = await start(savedPrefs: {'auth.biometricEnabled': true}, savedToken: 'refresh-1');

      expect(await unlockError(container), isNull);
      expect(container.read(authControllerProvider), isA<SignedIn>());
    });

    test('explains when nothing is enrolled on the phone', () async {
      sensor(BiometricKind.fingerprint, enrolled: false);
      final container = await start(savedPrefs: {'auth.biometricEnabled': true}, savedToken: 'refresh-1');

      final error = await unlockError(container);
      expect((error as BiometricException).reason, BiometricFailure.notEnrolled);
      verifyNever(() => biometrics.authenticate(any()));
    });

    test('needs one password sign-in with biometrics turned on first', () async {
      final container = await start();
      final error = await unlockError(container);
      expect((error as BiometricException).reason, BiometricFailure.notSetUp);
    });

    test('a cancelled prompt leaves the user signed out', () async {
      when(() => biometrics.authenticate(any())).thenThrow(const BiometricException(BiometricFailure.canceled));
      final container = await start(savedPrefs: {'auth.biometricEnabled': true}, savedToken: 'refresh-1');

      final error = await unlockError(container);
      expect((error as BiometricException).reason, BiometricFailure.canceled);
      expect(container.read(authControllerProvider), isA<SignedOut>());
      expect(repo.refreshCalls, 0);
    });

    test('no sensor at all', () async {
      sensor(BiometricKind.none, enrolled: false);
      final container = await start(savedPrefs: {'auth.biometricEnabled': true}, savedToken: 'refresh-1');
      final error = await unlockError(container);
      expect((error as BiometricException).reason, BiometricFailure.notAvailable);
    });
  });

  test('sign out wipes the saved session and biometric setting', () async {
    when(() => biometrics.authenticate(any())).thenAnswer((_) async {});
    final container = await start();
    final auth = container.read(authControllerProvider.notifier);
    await auth.login('emilys', 'emilyspass', rememberMe: true);
    await auth.enableBiometrics('reason');
    expect(prefs.getBool('auth.biometricEnabled'), isTrue);

    await auth.signOut();

    expect(container.read(authControllerProvider), isA<SignedOut>());
    expect(container.read(tokenHolderProvider).hasSession, isFalse);
    expect(secure.values, isEmpty);
    expect(prefs.getBool('auth.biometricEnabled'), isFalse);
  });
}
