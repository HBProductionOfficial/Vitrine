import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrine/src/core/biometrics/biometric_service.dart';
import 'package:vitrine/src/core/storage/preferences.dart';
import 'package:vitrine/src/core/storage/secure_store.dart';
import 'package:vitrine/src/features/auth/data/dummy_json_auth_repository.dart';
import 'package:vitrine/src/features/auth/presentation/login_screen.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/test_app.dart';

void main() {
  late MockBiometrics biometrics;

  Future<void> pumpLogin(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      testApp(
        const LoginScreen(),
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          secureStoreProvider.overrideWithValue(MemorySecureStore()),
          biometricServiceProvider.overrideWithValue(biometrics),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  final signInButton = find.widgetWithText(FilledButton, 'Sign in');
  final fields = find.byType(TextFormField);

  setUp(() {
    biometrics = MockBiometrics();
    when(() => biometrics.check()).thenAnswer((_) async => BiometricSupport.unavailable);
  });

  testWidgets('empty fields say what is missing', (tester) async {
    await pumpLogin(tester);

    await tester.tap(signInButton);
    await tester.pump();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('a wrong password shows one clear message', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(fields.at(0), 'emilys');
    await tester.enterText(fields.at(1), 'not-it');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Wrong username or password.'), findsOneWidget);
  });

  testWidgets('"Fill it in" types the demo account', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Fill it in'));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'emilys'), findsOneWidget);
  });

  testWidgets('no biometric button without a sensor', (tester) async {
    await pumpLogin(tester);
    expect(find.textContaining('biometrics'), findsNothing);
    expect(find.textContaining('fingerprint'), findsNothing);
  });

  testWidgets('the fingerprint button shows when the phone has a sensor', (tester) async {
    when(
      () => biometrics.check(),
    ).thenAnswer((_) async => const BiometricSupport(BiometricKind.fingerprint, enrolled: true));
    await pumpLogin(tester);
    expect(find.text('Sign in with fingerprint'), findsOneWidget);
  });
}
