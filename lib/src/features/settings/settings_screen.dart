import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../core/app_info.dart';
import '../../core/biometrics/biometric_service.dart';
import '../../core/design/palette.dart';
import '../../core/design/tokens.dart';
import '../../core/errors.dart';
import '../../core/links.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/page_body.dart';
import '../auth/presentation/auth_controller.dart';
import '../auth/presentation/widgets/sign_out.dart';
import 'settings_controller.dart';
import 'widgets/settings_rows.dart';

/// Language names are shown in their own language, so they're not translated.
const languageNames = {'en': 'English', 'ka': 'ქართული', 'ru': 'Русский'};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref, String? current) async {
    final l10n = AppLocalizations.of(context);
    // A record, so "same as phone" (null) can be told apart from closing the sheet.
    final picked = await showAppSheet<(String?,)>(
      context,
      builder: (sheet) => OptionSheet(
        title: l10n.language,
        options: [
          for (final code in [null, ...languageNames.keys])
            OptionTile(
              label: languageNames[code] ?? l10n.languageSystem,
              hint: code == null ? l10n.languageSystemHint : null,
              badgeText: code?.toUpperCase(),
              badgeIcon: code == null ? Icons.smartphone_rounded : null,
              selected: code == current,
              onTap: () => Navigator.pop(sheet, (code,)),
            ),
        ],
      ),
    );
    if (picked != null) await ref.read(settingsProvider.notifier).setLocale(picked.$1);
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref, ThemeMode current) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppSheet<ThemeMode>(
      context,
      builder: (sheet) => OptionSheet(
        title: l10n.appearance,
        options: [
          for (final (mode, icon) in [
            (ThemeMode.system, Icons.smartphone_rounded),
            (ThemeMode.light, Icons.light_mode_outlined),
            (ThemeMode.dark, Icons.dark_mode_outlined),
          ])
            OptionTile(
              label: themeLabel(mode, l10n),
              hint: mode == ThemeMode.system ? l10n.themeSystemHint : null,
              badgeIcon: icon,
              selected: mode == current,
              onTap: () => Navigator.pop(sheet, mode),
            ),
        ],
      ),
    );
    if (picked != null) await ref.read(settingsProvider.notifier).setThemeMode(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authControllerProvider);
    final version = ref.watch(appVersionProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: PageBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.xxl),
          children: [
            SettingsGroup(
              title: l10n.general,
              children: [
                SettingsRow(
                  icon: Icons.translate_rounded,
                  label: l10n.language,
                  value: languageNames[settings.localeCode] ?? l10n.languageSystem,
                  onTap: () => _pickLanguage(context, ref, settings.localeCode),
                ),
                SettingsRow(
                  icon: Icons.dark_mode_outlined,
                  label: l10n.appearance,
                  value: themeLabel(settings.themeMode, l10n),
                  onTap: () => _pickTheme(context, ref, settings.themeMode),
                ),
              ],
            ),
            if (auth is SignedIn)
              SettingsGroup(
                title: l10n.security,
                children: [_BiometricRow(auth: auth)],
              ),
            SettingsGroup(
              title: l10n.about,
              children: [
                SettingsRow(icon: Icons.info_outline_rounded, label: l10n.version, value: version),
                SettingsRow(
                  icon: Icons.code_rounded,
                  label: l10n.sourceCode,
                  external: true,
                  onTap: () => openLink(context, Links.source),
                ),
                SettingsRow(
                  icon: Icons.bug_report_outlined,
                  label: l10n.reportProblem,
                  external: true,
                  onTap: () => openLink(context, Links.newIssue),
                ),
                SettingsRow(
                  icon: Icons.storefront_outlined,
                  label: l10n.productsSource,
                  external: true,
                  onTap: () => openLink(context, Links.dummyJson),
                ),
                SettingsRow(
                  icon: Icons.devices_other_outlined,
                  label: l10n.devicesSource,
                  external: true,
                  onTap: () => openLink(context, Links.restfulApi),
                ),
              ],
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: p.danger,
                side: BorderSide(color: p.danger.withValues(alpha: 0.5), width: 1.2),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => confirmSignOut(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(l10n.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

String themeLabel(ThemeMode mode, AppLocalizations l10n) {
  return switch (mode) {
    ThemeMode.system => l10n.themeSystem,
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
  };
}

class _BiometricRow extends ConsumerWidget {
  const _BiometricRow({required this.auth});

  final SignedIn auth;

  Future<void> _set(BuildContext context, WidgetRef ref, bool on) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(authControllerProvider.notifier);
    try {
      if (on) {
        await controller.enableBiometrics(l10n.biometricEnableReason);
      } else {
        await controller.disableBiometrics();
      }
    } catch (e) {
      if (context.mounted) showSnack(context, describeError(e, l10n));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kind = auth.biometricKind;
    final available = kind != BiometricKind.none;
    final enabled = auth.biometricEnabled;

    return SettingsRow(
      icon: kind == BiometricKind.face ? Icons.face_rounded : Icons.fingerprint_rounded,
      label: switch (kind) {
        BiometricKind.face => l10n.biometricToggleFace,
        BiometricKind.fingerprint => l10n.biometricToggleFingerprint,
        _ => l10n.biometricToggleGeneric,
      },
      hint: available ? l10n.biometricHint : l10n.biometricUnavailable,
      onTap: available ? () => _set(context, ref, !enabled) : null,
      trailing: Switch(value: enabled, onChanged: available ? (on) => _set(context, ref, on) : null),
    );
  }
}
