import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrine/src/core/design/palette.dart';
import 'package:vitrine/src/features/devices/data/restful_devices_repository.dart';
import 'package:vitrine/src/features/devices/presentation/devices_controller.dart';
import 'package:vitrine/src/features/devices/presentation/devices_screen.dart';
import 'package:vitrine/src/features/devices/presentation/widgets/flash_on_change.dart';

import '../../helpers/fake_devices.dart';
import '../../helpers/test_app.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        const DevicesScreen(),
        overrides: [
          devicesRepositoryProvider.overrideWithValue(FakeDevicesRepository()),
          telemetrySimulatorProvider.overrideWithValue(SteadySimulator()),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DevicesScreen)));

  testWidgets('rows show only the id and name until opened', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Google Pixel 6 Pro'), findsOneWidget);
    expect(find.text('Cloudy White'), findsNothing);
    expect(find.text('Live readings'), findsNothing);
  });

  testWidgets('opening a row closes the one that was open', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Google Pixel 6 Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Cloudy White'), findsOneWidget);
    expect(find.text('Live readings'), findsOneWidget);

    await tester.tap(find.text('Apple iPhone 12 Mini'));
    await tester.pumpAndSettle();
    expect(find.text('Cloudy White'), findsNothing);
    expect(find.text('Blue'), findsOneWidget);
  });

  testWidgets('closed devices get a dot when their readings change', (tester) async {
    await pumpScreen(tester);
    // The row's InkWell merges the dot's label into its own, so look for the widget.
    final updated = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Updated since you last opened it',
    );
    expect(updated, findsNothing);

    await tester.tap(find.text('Google Pixel 6 Pro'));
    await tester.pumpAndSettle();
    containerOf(tester).read(devicesControllerProvider.notifier).tick();
    await tester.pump();

    // Devices 3 and 7 are closed; 1 is open, so its values blink instead.
    expect(updated, findsNWidgets(2));
    expect(find.text('79%'), findsOneWidget);

    await tester.tap(find.text('Apple MacBook Pro 16'));
    await tester.pumpAndSettle();
    expect(updated, findsNWidgets(1));
  });

  testWidgets('a changed value is highlighted, then fades back', (tester) async {
    Color? background() {
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(FlashOnChange), matching: find.byType(DecoratedBox)).first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    Widget reading(int value) => testApp(FlashOnChange(value: value, child: Text('$value')));

    await tester.pumpWidget(reading(80));
    expect(background(), Palette.light.surfaceMuted);

    await tester.pumpWidget(reading(79));
    await tester.pump(const Duration(milliseconds: 100));
    expect(background(), Palette.light.accentSoft);

    await tester.pump(const Duration(milliseconds: 1400));
    expect(background(), Palette.light.surfaceMuted);
  });
}
