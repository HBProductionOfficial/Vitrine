import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:vitrine/l10n/gen/app_localizations.dart';
import 'package:vitrine/src/core/design/palette.dart';

/// The app's widgets need the palette and translations, but not the real
/// theme: that one pulls Manrope through google_fonts, which tries to
/// download it, and tests have no network.
Widget testApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(extensions: const [Palette.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
