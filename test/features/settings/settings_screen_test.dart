import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/core/app_info.dart';
import 'package:vitrine/src/core/biometrics/biometric_service.dart';
import 'package:vitrine/src/core/storage/preferences.dart';
import 'package:vitrine/src/features/auth/presentation/auth_controller.dart';
import 'package:vitrine/src/features/settings/settings_screen.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/test_app.dart';

/// Skips the real session restore and starts signed in with [initial].
class _SignedInAs extends AuthController {
  _SignedInAs(this.initial);

  final SignedIn initial;

  @override
  AuthState build() => initial;
}

void main() {
  Future<void> pumpSettings(WidgetTester tester, SignedIn auth) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      testApp(
        const SettingsScreen(),
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
          authControllerProvider.overrideWith(() => _SignedInAs(auth)),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a phone without a sensor gets no biometric section at all', (tester) async {
    await pumpSettings(tester, const SignedIn(user: emily));

    expect(find.text('Security'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('a sensor with nothing set up says what to add', (tester) async {
    await pumpSettings(tester, const SignedIn(user: emily, biometricKind: BiometricKind.fingerprint));

    expect(find.text('Sign in with fingerprint'), findsOneWidget);
    expect(find.text('Add a fingerprint or face in your phone settings first'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('a phone with both sensors names both', (tester) async {
    await pumpSettings(
      tester,
      const SignedIn(user: emily, biometricKind: BiometricKind.faceOrFingerprint, biometricEnrolled: true),
    );

    expect(find.text('Sign in with face or fingerprint'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
  });
}
