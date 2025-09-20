import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/app.dart';
import 'package:vitrine/src/core/biometrics/biometric_service.dart';
import 'package:vitrine/src/core/network/api_clients.dart';
import 'package:vitrine/src/core/storage/preferences.dart';
import 'package:vitrine/src/core/storage/secure_store.dart';
import 'package:vitrine/src/features/devices/domain/telemetry.dart';
import 'package:vitrine/src/features/devices/presentation/devices_controller.dart';

import 'fake_backend.dart';

/// The emulator in CI has no fingerprint set up; biometrics have their own
/// unit and widget tests.
class NoBiometrics implements BiometricService {
  @override
  Future<BiometricSupport> check() async => BiometricSupport.unavailable;

  @override
  Future<void> authenticate(String reason) async => throw const BiometricException(BiometricFailure.notAvailable);
}

/// Every tick drains one percent of battery, so the test knows what to expect.
class SteadySimulator extends TelemetrySimulator {
  @override
  Telemetry initial() => const Telemetry(batteryLevel: 80, temperature: 34, cpuLoad: 20, wifiSignal: -60);

  @override
  (Telemetry, Set<TelemetryField>) next(Telemetry current) {
    return (current.copyWith(batteryLevel: current.batteryLevel - 1), {TelemetryField.batteryLevel});
  }
}

/// Starts the real app with a clean slate: nothing saved, English, and the
/// fake server in place of the network.
Future<FakeBackend> launchApp(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString('settings.locale', 'en');
  final backend = FakeBackend();

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        secureStoreProvider.overrideWithValue(MemorySecureStore()),
        biometricServiceProvider.overrideWithValue(NoBiometrics()),
        httpAdapterProvider.overrideWithValue(backend),
        telemetrySimulatorProvider.overrideWithValue(SteadySimulator()),
      ],
      child: const VitrineApp(),
    ),
  );
  await tester.waitFor(find.text('Fill it in'));
  return backend;
}

final signInButton = find.widgetWithText(FilledButton, 'Sign in');

Future<void> signInAsDemoUser(WidgetTester tester) async {
  await tester.tapAndSettle(find.text('Fill it in'));
  await tester.tapOn(signInButton);
  await tester.waitFor(find.text('Essence Mascara Lash Princess'));
}

Finder tab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

extension WaitFor on WidgetTester {
  /// Pumps frames until [finder] matches, for things that arrive over the
  /// (fake) network or on a timer. With [settle] off it returns as soon as
  /// it appears, before any animation it started has finished.
  Future<void> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 10), bool settle = true}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) throw TestFailure('Gave up waiting for $finder');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await pump();
    }
    if (settle) await pumpAndSettle();
  }

  Future<void> waitUntilGone(Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(end)) throw TestFailure('Still showing $finder');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await pump();
    }
    await pumpAndSettle();
  }

  /// Closes the keyboard and scrolls [finder] into view before tapping, the
  /// way a person would.
  Future<void> tapAndSettle(Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpAndSettle();
    await ensureVisible(finder);
    await pumpAndSettle();
    await tap(finder);
    await pumpAndSettle();
  }

  /// Like [tapAndSettle], for taps whose result arrives later; follow it with
  /// [waitFor].
  Future<void> tapOn(Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpAndSettle();
    await ensureVisible(finder);
    await pumpAndSettle();
    await tap(finder);
    await pump();
  }
}
