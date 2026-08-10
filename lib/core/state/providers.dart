import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../prefs/app_preferences.dart';

final databaseProvider = FutureProvider<Database>((ref) {
  return AppDatabase.open();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Loads the local profile; null until onboarding completes.
final profileProvider = AsyncNotifierProvider<ProfileController, UserProfile?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserProfile?> {
  late final ProfileRepository _repository;

  @override
  Future<UserProfile?> build() async {
    final db = await ref.watch(databaseProvider.future);
    _repository = ProfileRepository(db);
    return _repository.get();
  }

  Future<void> save(UserProfile profile) async {
    await _repository.save(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const AsyncData(null);
  }
}

final themePreferenceProvider =
    NotifierProvider<ThemePreferenceController, AppearancePreference>(
  ThemePreferenceController.new,
);

class ThemePreferenceController extends Notifier<AppearancePreference> {
  @override
  AppearancePreference build() {
    final prefs = ref.watch(sharedPreferencesProvider).value;
    return prefs?.appearance ?? AppearancePreference.system;
  }

  Future<void> setAppearance(AppearancePreference value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setAppearance(value);
    state = value;
  }
}

final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(themePreferenceProvider)) {
    AppearancePreference.light => ThemeMode.light,
    AppearancePreference.dark => ThemeMode.dark,
    AppearancePreference.system => ThemeMode.system,
  };
});
