import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable appearance mode, mirroring system theme when [system].
enum AppearancePreference { system, light, dark }

AppearancePreference appearanceFromKey(String? value) {
  return switch (value) {
    'light' => AppearancePreference.light,
    'dark' => AppearancePreference.dark,
    _ => AppearancePreference.system,
  };
}

String appearanceKey(AppearancePreference value) => switch (value) {
      AppearancePreference.system => 'system',
      AppearancePreference.light => 'light',
      AppearancePreference.dark => 'dark',
    };

/// Thin, typed wrapper over SharedPreferences for app-level settings that are
/// not part of the user profile (appearance, reminders).
class AppPreferences {
  AppPreferences(this._prefs);

  static const String appearancePrefKey = 'appearance';

  final SharedPreferences _prefs;

  AppearancePreference get appearance =>
      appearanceFromKey(_prefs.getString(appearancePrefKey));

  Future<void> setAppearance(AppearancePreference value) {
    return _prefs.setString(appearancePrefKey, appearanceKey(value));
  }
}
