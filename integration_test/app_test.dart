import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vitrine/src/core/design/palette.dart';
import 'package:vitrine/src/features/devices/presentation/widgets/device_tile.dart';
import 'package:vitrine/src/features/devices/presentation/widgets/flash_on_change.dart';

import 'support/harness.dart';

// Whole journeys through the real app on a device, with a fake server in
// place of DummyJSON and restful-api.dev.
//
//   flutter test integration_test -d <device id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search, add to cart, change the amount and check out', (tester) async {
    final backend = await launchApp(tester);
    await signInAsDemoUser(tester);

    await tester.enterText(find.byType(TextField).first, 'lipstick');
    await tester.waitUntilGone(find.text('Essence Mascara Lash Princess'));
    expect(find.text('Red Lipstick'), findsOneWidget);

    await tester.tapAndSettle(find.text('Red Lipstick'));
    await tester.tapAndSettle(find.byTooltip('Add one'));
    await tester.tapAndSettle(find.byTooltip('Add one'));
    await tester.tapOn(find.text('Add to cart'));
    await tester.waitFor(find.text('View cart'));

    // Once it's in the cart, the same stepper changes the cart.
    await tester.tapAndSettle(find.byTooltip('Add one'));
    await tester.tapAndSettle(find.text('View cart'));
    expect(find.text('Red Lipstick'), findsOneWidget);
    expect(find.text(r'$45.64'), findsWidgets);

    await tester.tapAndSettle(find.byTooltip('Remove one'));
    expect(find.text(r'$34.23'), findsWidgets);

    await tester.tapAndSettle(find.text('Check out'));
    await tester.waitFor(find.textContaining('Emily Johnson'));
    await tester.tapOn(find.text('Place order'));
    await tester.waitFor(find.text('Order placed'));
    expect(backend.placedOrders.single['products'], [
      {'id': 4, 'quantity': 3},
    ]);

    await tester.tapAndSettle(find.text('See your orders'));
    expect(find.text('Placed in Vitrine'), findsOneWidget);
    expect(find.text('3 items'), findsOneWidget);
    await tester.waitFor(find.text('Order #1'));
  });

  testWidgets('an open device blinks and a closed one gets a dot when readings change', (tester) async {
    await launchApp(tester);
    await signInAsDemoUser(tester);

    await tester.tapAndSettle(tab('Devices'));
    await tester.waitFor(find.text('Google Pixel 6 Pro'));
    await tester.tapAndSettle(find.text('Google Pixel 6 Pro'));
    expect(find.text('Live readings'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);

    final iPhoneTile = find.ancestor(of: find.text('Apple iPhone 12 Pro Max'), matching: find.byType(DeviceTile));
    final iPhoneDot = find.descendant(
      of: iPhoneTile,
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Updated since you last opened it',
      ),
    );
    expect(iPhoneDot, findsNothing);

    // The simulator ticks every 10 seconds.
    await tester.waitFor(find.text('79%'), timeout: const Duration(seconds: 15), settle: false);

    Color? flash() {
      final tile = find.ancestor(of: find.text('79%'), matching: find.byType(FlashOnChange));
      final box = tester.widget<DecoratedBox>(find.descendant(of: tile, matching: find.byType(DecoratedBox)).first);
      return (box.decoration as BoxDecoration).color;
    }

    final palette = Theme.of(tester.element(find.text('79%'))).extension<Palette>()!;
    expect(flash(), isNot(palette.surfaceMuted), reason: 'the changed reading should be highlighted');
    expect(iPhoneDot, findsOneWidget);

    await Future<void>.delayed(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(flash(), palette.surfaceMuted, reason: 'the highlight should fade back');

    await tester.tapAndSettle(find.text('Apple iPhone 12 Pro Max'));
    expect(iPhoneDot, findsNothing);
  });

  testWidgets('a wrong password says so, and the app recovers when the server comes back', (tester) async {
    final backend = await launchApp(tester);
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'emilys');
    await tester.enterText(fields.at(1), 'not-the-password');
    await tester.tapOn(signInButton);
    await tester.waitFor(find.text('Wrong username or password.'));

    backend.offline = true;
    await tester.tapAndSettle(find.text('Fill it in'));
    await tester.tapOn(signInButton);
    await tester.waitFor(find.text('No connection. Check your internet and try again.'));

    backend.offline = false;
    await tester.tapOn(signInButton);
    await tester.waitFor(find.text('Essence Mascara Lash Princess'));

    // The server goes away mid-session and comes back.
    backend.offline = true;
    await tester.tapOn(find.text('Beauty'));
    await tester.waitFor(find.text('Try again'));

    backend.offline = false;
    await tester.tapOn(find.text('Try again'));
    await tester.waitFor(find.text('Red Lipstick'));
    expect(find.text('Calvin Klein CK One'), findsNothing);
  });
}
