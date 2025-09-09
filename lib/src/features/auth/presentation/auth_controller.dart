import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/biometrics/biometric_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_holder.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/storage/secure_store.dart';
import '../data/dummy_json_auth_repository.dart';
import '../domain/user.dart';

sealed class AuthState {
  const AuthState();
}

/// Checking for a saved session on launch.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class SignedOut extends AuthState {
  const SignedOut({this.biometricKind = BiometricKind.none, this.biometricReady = false, this.reason});

  final BiometricKind biometricKind;

  /// A session is saved and biometric unlock is turned on.
  final bool biometricReady;

  /// Why the user ended up here, e.g. an expired session. Shown once on the
  /// login screen.
  final Object? reason;
}

class SignedIn extends AuthState {
  const SignedIn({
    required this.user,
    this.biometricKind = BiometricKind.none,
    this.biometricEnabled = false,
    this.offerBiometrics = false,
  });

  final User user;
  final BiometricKind biometricKind;
  final bool biometricEnabled;

  /// Ask once after a password sign-in whether to turn on biometric unlock.
  final bool offerBiometrics;

  SignedIn copyWith({bool? biometricEnabled, bool? offerBiometrics}) => SignedIn(
    user: user,
    biometricKind: biometricKind,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    offerBiometrics: offerBiometrics ?? this.offerBiometrics,
  );
}

class AuthController extends Notifier<AuthState> {
  @visibleForTesting
  static const refreshTokenKey = 'auth.refreshToken';
  static const _rememberKey = 'auth.rememberMe';
  static const _biometricKey = 'auth.biometricEnabled';
  static const _offerDeclinedKey = 'auth.biometricOfferDeclined';

  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthRestoring();
  }

  bool get _rememberMe => ref.read(preferencesProvider).getBool(_rememberKey) ?? false;
  bool get _biometricEnabled => ref.read(preferencesProvider).getBool(_biometricKey) ?? false;

  Future<void> _restore() async {
    final support = await ref.read(biometricServiceProvider).check();
    final kind = support.kind;
    final saved = await ref.read(secureStoreProvider).read(refreshTokenKey);
    if (!ref.mounted) return;

    if (saved == null) {
      state = SignedOut(biometricKind: kind);
      return;
    }
    if (_biometricEnabled && support.enrolled) {
      state = SignedOut(biometricKind: kind, biometricReady: true);
      return;
    }
    if (!_rememberMe) {
      await _forgetSession();
      state = SignedOut(biometricKind: kind);
      return;
    }
    try {
      await _resume(saved, kind);
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) await _forgetSession();
      if (ref.mounted) state = SignedOut(biometricKind: kind, reason: e);
    }
  }

  Future<void> _resume(String refreshToken, BiometricKind kind) async {
    final repo = ref.read(authRepositoryProvider);
    final tokens = await repo.refresh(refreshToken);
    ref.read(tokenHolderProvider).update(access: tokens.accessToken, refresh: tokens.refreshToken);
    final user = await repo.currentUser();
    await ref.read(secureStoreProvider).write(refreshTokenKey, tokens.refreshToken);
    if (!ref.mounted) return;
    state = SignedIn(user: user, biometricKind: kind, biometricEnabled: _biometricEnabled);
  }

  Future<void> login(String username, String password, {required bool rememberMe}) async {
    final (user, tokens) = await ref.read(authRepositoryProvider).login(username, password);
    ref.read(tokenHolderProvider).update(access: tokens.accessToken, refresh: tokens.refreshToken);

    final prefs = ref.read(preferencesProvider);
    await prefs.setBool(_rememberKey, rememberMe);
    final secure = ref.read(secureStoreProvider);
    if (rememberMe || _biometricEnabled) {
      await secure.write(refreshTokenKey, tokens.refreshToken);
    } else {
      await secure.delete(refreshTokenKey);
    }

    final support = await ref.read(biometricServiceProvider).check();
    final offer = support.enrolled && !_biometricEnabled && !(prefs.getBool(_offerDeclinedKey) ?? false);
    state = SignedIn(
      user: user,
      biometricKind: support.kind,
      biometricEnabled: _biometricEnabled,
      offerBiometrics: offer,
    );
  }

  /// The assignment's "Login with Biometrics": unlocks the session saved by an
  /// earlier password sign-in.
  Future<void> unlockWithBiometrics(String reason) async {
    final support = await ref.read(biometricServiceProvider).check();
    final kind = support.kind;
    if (kind == BiometricKind.none) throw const BiometricException(BiometricFailure.notAvailable);
    if (!support.enrolled) throw const BiometricException(BiometricFailure.notEnrolled);
    final saved = await ref.read(secureStoreProvider).read(refreshTokenKey);
    if (!_biometricEnabled || saved == null) {
      throw const BiometricException(BiometricFailure.notSetUp);
    }
    await ref.read(biometricServiceProvider).authenticate(reason);
    try {
      await _resume(saved, kind);
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) {
        await _forgetSession();
        if (ref.mounted) state = SignedOut(biometricKind: kind);
      }
      rethrow;
    }
  }

  Future<void> enableBiometrics(String reason) async {
    await ref.read(biometricServiceProvider).authenticate(reason);
    final refresh = ref.read(tokenHolderProvider).refreshToken;
    if (refresh != null) await ref.read(secureStoreProvider).write(refreshTokenKey, refresh);
    final prefs = ref.read(preferencesProvider);
    await prefs.setBool(_biometricKey, true);
    await prefs.remove(_offerDeclinedKey);
    final current = state;
    if (current is SignedIn) state = current.copyWith(biometricEnabled: true, offerBiometrics: false);
  }

  Future<void> disableBiometrics() async {
    await ref.read(preferencesProvider).setBool(_biometricKey, false);
    if (!_rememberMe) await ref.read(secureStoreProvider).delete(refreshTokenKey);
    final current = state;
    if (current is SignedIn) state = current.copyWith(biometricEnabled: false);
  }

  Future<void> declineBiometricOffer() async {
    await ref.read(preferencesProvider).setBool(_offerDeclinedKey, true);
    final current = state;
    if (current is SignedIn) state = current.copyWith(offerBiometrics: false);
  }

  Future<void> signOut() async {
    final kind = switch (state) {
      SignedIn(:final biometricKind) => biometricKind,
      SignedOut(:final biometricKind) => biometricKind,
      AuthRestoring() => BiometricKind.none,
    };
    ref.read(tokenHolderProvider).clear();
    await _forgetSession();
    state = SignedOut(biometricKind: kind);
  }

  /// Called by the HTTP layer when the refresh token stops working.
  void onSessionExpired() {
    final current = state;
    if (current is! SignedIn) return;
    ref.read(tokenHolderProvider).clear();
    unawaited(_forgetSession());
    state = SignedOut(biometricKind: current.biometricKind, reason: const ApiException(ApiErrorKind.unauthorized));
  }

  Future<void> _forgetSession() async {
    await ref.read(secureStoreProvider).delete(refreshTokenKey);
    final prefs = ref.read(preferencesProvider);
    await prefs.setBool(_rememberKey, false);
    await prefs.setBool(_biometricKey, false);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Full profile for the Profile tab; the login response only has the basics.
final currentUserProvider = FutureProvider<User>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! SignedIn) throw StateError('Not signed in');
  return ref.read(authRepositoryProvider).currentUser();
});
