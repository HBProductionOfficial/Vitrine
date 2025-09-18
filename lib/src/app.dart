import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import 'core/design/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/settings/settings_controller.dart';

class VitrineApp extends ConsumerStatefulWidget {
  const VitrineApp({super.key});

  @override
  ConsumerState<VitrineApp> createState() => _VitrineAppState();
}

class _VitrineAppState extends ConsumerState<VitrineApp> {
  // Someone who leaves to add a fingerprint in phone settings sees the
  // option light up when they come back.
  late final _lifecycle = AppLifecycleListener(
    onResume: () => ref.read(authControllerProvider.notifier).refreshBiometrics(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 320),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
