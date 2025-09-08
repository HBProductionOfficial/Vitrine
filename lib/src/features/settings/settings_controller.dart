import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences.dart';

@immutable
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.localeCode});

  final ThemeMode themeMode;

  /// Null follows the phone's language.
  final String? localeCode;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({ThemeMode? themeMode, String? localeCode, bool clearLocale = false}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    );
  }
}

class SettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'settings.theme';
  static const _localeKey = 'settings.locale';

  @override
  AppSettings build() {
    final prefs = ref.watch(preferencesProvider);
    final theme = ThemeMode.values.asNameMap()[prefs.getString(_themeKey)] ?? ThemeMode.system;
    return AppSettings(themeMode: theme, localeCode: prefs.getString(_localeKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(preferencesProvider).setString(_themeKey, mode.name);
  }

  Future<void> setLocale(String? code) async {
    state = state.copyWith(localeCode: code, clearLocale: code == null);
    final prefs = ref.read(preferencesProvider);
    if (code == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, code);
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
