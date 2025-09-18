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
  const SignedOut({
    this.biometricKind = BiometricKind.none,
    this.biometricEnrolled = false,
    this.biometricReady = false,
    this.reason,
  });

  final BiometricKind biometricKind;

  /// A fingerprint or face is set up on the phone, so the prompt can work.
  final bool biometricEnrolled;

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
    this.biometricEnrolled = false,
    this.biometricEnabled = false,
    this.offerBiometrics = false,
  });

  final User user;
  final BiometricKind biometricKind;
  final bool biometricEnrolled;
  final bool biometricEnabled;

  /// Ask once after a password sign-in whether to turn on biometric unlock.
  final bool offerBiometrics;

  SignedIn copyWith({
    BiometricKind? biometricKind,
    bool? biometricEnrolled,
    bool? biometricEnabled,
    bool? offerBiometrics,
  }) => SignedIn(
    user: user,
    biometricKind: biometricKind ?? this.biometricKind,
    biometricEnrolled: biometricEnrolled ?? this.biometricEnrolled,
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

  /// What the phone could do at the last check.
  BiometricSupport _support = BiometricSupport.unavailable;

  SignedOut _signedOut({bool ready = false, Object? reason}) => SignedOut(
    biometricKind: _support.kind,
    biometricEnrolled: _support.enrolled,
    biometricReady: ready,
    reason: reason,
  );

  bool get _rememberMe => ref.read(preferencesProvider).getBool(_rememberKey) ?? false;
  bool get _biometricEnabled => ref.read(preferencesProvider).getBool(_biometricKey) ?? false;

  Future<void> _restore() async {
    _support = await ref.read(biometricServiceProvider).check();
    final saved = await ref.read(secureStoreProvider).read(refreshTokenKey);
    if (!ref.mounted) return;

    if (saved == null) {
      state = _signedOut();
      return;
    }
    if (_biometricEnabled && _support.enrolled) {
      state = _signedOut(ready: true);
      return;
    }
    if (!_rememberMe) {
      await _forgetSession();
      state = _signedOut();
      return;
    }
    try {
      await _resume(saved);
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) await _forgetSession();
      if (ref.mounted) state = _signedOut(reason: e);
    }
  }

  /// Checks the sensors again, e.g. when the user comes back from phone
  /// settings after adding a fingerprint.
  Future<void> refreshBiometrics() async {
    final support = await ref.read(biometricServiceProvider).check();
    if (!ref.mounted) return;
    _support = support;
    state = switch (state) {
      final SignedIn s => s.copyWith(biometricKind: support.kind, biometricEnrolled: support.enrolled),
      final SignedOut s => _signedOut(ready: s.biometricReady && support.enrolled, reason: s.reason),
      final AuthRestoring s => s,
    };
  }

  Future<void> _resume(String refreshToken) async {
    final repo = ref.read(authRepositoryProvider);
    final tokens = await repo.refresh(refreshToken);
    ref.read(tokenHolderProvider).update(access: tokens.accessToken, refresh: tokens.refreshToken);
    final user = await repo.currentUser();
    await ref.read(secureStoreProvider).write(refreshTokenKey, tokens.refreshToken);
    if (!ref.mounted) return;
    state = SignedIn(
      user: user,
      biometricKind: _support.kind,
      biometricEnrolled: _support.enrolled,
      biometricEnabled: _biometricEnabled,
    );
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

    _support = await ref.read(biometricServiceProvider).check();
    final offer = _support.enrolled && !_biometricEnabled && !(prefs.getBool(_offerDeclinedKey) ?? false);
    state = SignedIn(
      user: user,
      biometricKind: _support.kind,
      biometricEnrolled: _support.enrolled,
      biometricEnabled: _biometricEnabled,
      offerBiometrics: offer,
    );
  }

  /// The assignment's "Login with Biometrics": unlocks the session saved by an
  /// earlier password sign-in.
  Future<void> unlockWithBiometrics(String reason) async {
    final support = _support = await ref.read(biometricServiceProvider).check();
    if (support.kind == BiometricKind.none) throw const BiometricException(BiometricFailure.notAvailable);
    if (!support.enrolled) throw const BiometricException(BiometricFailure.notEnrolled);
    final saved = await ref.read(secureStoreProvider).read(refreshTokenKey);
    if (!_biometricEnabled || saved == null) {
      throw const BiometricException(BiometricFailure.notSetUp);
    }
    await ref.read(biometricServiceProvider).authenticate(reason);
    try {
      await _resume(saved);
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) {
        await _forgetSession();
        if (ref.mounted) state = _signedOut();
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
    ref.read(tokenHolderProvider).clear();
    await _forgetSession();
    state = _signedOut();
  }

  /// Called by the HTTP layer after it refreshed the session. A saved session
  /// has to follow, or the next launch would start from the old token.
  void onTokensRefreshed(String refreshToken) {
    if (_rememberMe || _biometricEnabled) {
      unawaited(ref.read(secureStoreProvider).write(refreshTokenKey, refreshToken));
    }
  }

  /// Called by the HTTP layer when the refresh token stops working.
  void onSessionExpired() {
    final current = state;
    if (current is! SignedIn) return;
    ref.read(tokenHolderProvider).clear();
    unawaited(_forgetSession());
    state = _signedOut(reason: const ApiException(ApiErrorKind.unauthorized));
  }

  Future<void> _forgetSession() async {
    await ref.read(secureStoreProvider).delete(refreshTokenKey);
    final prefs = ref.read(preferencesProvider);
    await prefs.setBool(_rememberKey, false);
    await prefs.setBool(_biometricKey, false);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Id of the signed-in user. Cart and saved items are stored per account.
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s is SignedIn ? s.user.id : null)),
);

/// Full profile for the Profile tab; the login response only has the basics.
final currentUserProvider = FutureProvider<User>((ref) {
  if (ref.watch(currentUserIdProvider) == null) throw StateError('Not signed in');
  return ref.read(authRepositoryProvider).currentUser();
});
