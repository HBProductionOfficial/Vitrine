import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/storage/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Retrying failed requests is handled per screen with a Retry button.
      retry: (_, _) => null,
      overrides: [preferencesProvider.overrideWithValue(prefs)],
      child: const VitrineApp(),
    ),
  );
}
