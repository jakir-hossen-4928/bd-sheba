import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool useInAppBrowser;

  SettingsState({
    required this.themeMode,
    required this.locale,
    this.useInAppBrowser = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? useInAppBrowser,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      useInAppBrowser: useInAppBrowser ?? this.useInAppBrowser,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _prefs;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPrefsProvider);
    return SettingsState(
      themeMode: _loadTheme(_prefs),
      locale: _loadLocale(_prefs),
      useInAppBrowser: _loadBrowserPref(_prefs),
    );
  }

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final theme = prefs.getString('themeMode') ?? 'system';
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Locale _loadLocale(SharedPreferences prefs) {
    final langCode = prefs.getString('languageCode') ?? 'bn';
    return Locale(langCode);
  }

  static bool _loadBrowserPref(SharedPreferences prefs) {
    return prefs.getBool('useInAppBrowser') ?? true;
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString('themeMode', mode.name);
  }

  void toggleLanguage() {
    final newLocale = state.locale.languageCode == 'bn'
        ? const Locale('en')
        : const Locale('bn');
    state = state.copyWith(locale: newLocale);
    _prefs.setString('languageCode', newLocale.languageCode);
  }

  void toggleBrowserPref() {
    final newValue = !state.useInAppBrowser;
    state = state.copyWith(useInAppBrowser: newValue);
    _prefs.setBool('useInAppBrowser', newValue);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
