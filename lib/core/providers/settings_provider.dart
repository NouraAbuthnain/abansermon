import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preferences_service.dart';

// Provides the PreferencesService instance. Will be overridden in main.dart.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('preferencesServiceProvider not initialized');
});

class SettingsState {
  final ThemeMode themeMode;
  final double textScaleFactor;
  final bool notifications;
  final String language;

  SettingsState({
    required this.themeMode,
    required this.textScaleFactor,
    required this.notifications,
    required this.language,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? textScaleFactor,
    bool? notifications,
    String? language,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final PreferencesService _prefsService;

  SettingsNotifier(this._prefsService)
      : super(SettingsState(
          themeMode: _parseThemeMode(_prefsService.themeMode),
          textScaleFactor: _prefsService.textScaleFactor,
          notifications: _prefsService.notifications,
          language: _prefsService.language,
        ));

  static ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _formatThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefsService.setThemeMode(_formatThemeMode(mode));
  }

  void updateTextScaleFactor(double scale) {
    state = state.copyWith(textScaleFactor: scale);
    _prefsService.setTextScaleFactor(scale);
  }

  void updateNotifications(bool enabled) {
    state = state.copyWith(notifications: enabled);
    _prefsService.setNotifications(enabled);
  }


  
  void updateLanguage(String language) {
    state = state.copyWith(language: language);
    _prefsService.setLanguage(language);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return SettingsNotifier(prefsService);
});
