import 'package:eco_action/core/prefs/app_preferences.dart';
import 'package:eco_action/core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('appearance preference round-trips through SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final appPrefs = AppPreferences(prefs);
    expect(appPrefs.appearance, AppearancePreference.system);

    await appPrefs.setAppearance(AppearancePreference.dark);
    expect(
      AppPreferences(await SharedPreferences.getInstance()).appearance,
      AppearancePreference.dark,
    );

    await appPrefs.setAppearance(AppearancePreference.light);
    expect(
      AppPreferences(await SharedPreferences.getInstance()).appearance,
      AppearancePreference.light,
    );
  });

  testWidgets('themeMode provider follows the persisted appearance',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(sharedPreferencesProvider.future);
    expect(container.read(themeModeProvider), ThemeMode.system);

    await container
        .read(themePreferenceProvider.notifier)
        .setAppearance(AppearancePreference.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await container
        .read(themePreferenceProvider.notifier)
        .setAppearance(AppearancePreference.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
