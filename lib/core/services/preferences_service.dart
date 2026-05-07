import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Theme Mode
  static const String _themeModeKey = 'themeMode';

  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(_themeModeKey, value);
  }

  // Text Scale Factor
  static const String _textScaleFactorKey = 'textScaleFactor';

  double get textScaleFactor => _prefs.getDouble(_textScaleFactorKey) ?? 1.0;

  Future<void> setTextScaleFactor(double value) async {
    await _prefs.setDouble(_textScaleFactorKey, value);
  }

  // Notifications
  static const String _notificationsKey = 'notifications';

  bool get notifications => _prefs.getBool(_notificationsKey) ?? false;

  Future<void> setNotifications(bool value) async {
    await _prefs.setBool(_notificationsKey, value);
  }

  // Language
  static const String _languageKey = 'language';

  String get language => _prefs.getString(_languageKey) ?? 'English';

  Future<void> setLanguage(String value) async {
    await _prefs.setString(_languageKey, value);
  }

  // Dev auth bypass (testing only)
  static const String _devAuthKey = 'devAuth';

  bool get isDevLoggedIn => _prefs.getBool(_devAuthKey) ?? false;

  Future<void> setDevLoggedIn(bool value) async {
    await _prefs.setBool(_devAuthKey, value);
  }
}
