import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/action_log_repository.dart';
import '../../data/repositories/badge_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/challenge_progress_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/eco_action.dart';
import '../../domain/models/emission_factor.dart';
import '../../domain/models/user_profile.dart';
import '../../features/challenges/progress_engine.dart';
import '../../features/community/community_engine.dart';
import '../../features/coach/coach_engine.dart';
import '../../features/home/dashboard_engine.dart';
import '../../features/impact/impact_engine.dart';
import '../../features/settings/data_port.dart';
import '../../features/settings/reminder_scheduler.dart';
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
  ProfileController({ProfileRepository? repository})
      : _repositoryOverride = repository;

  final ProfileRepository? _repositoryOverride;
  late final ProfileRepository _repository;

  @override
  Future<UserProfile?> build() async {
    final repository = _repositoryOverride;
    _repository = repository ??
        ProfileRepository(await ref.watch(databaseProvider.future));
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
    return prefs == null
        ? AppearancePreference.system
        : AppPreferences(prefs).appearance;
  }

  Future<void> setAppearance(AppearancePreference value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await AppPreferences(prefs).setAppearance(value);
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

/// Everything the home dashboard shows. Invalidated after each logged action.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return computeDashboardStats(ActionLogRepository(db), DateTime.now());
});

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository());

/// Read-only action catalog from assets.
final actionsProvider = FutureProvider<List<EcoAction>>((ref) {
  return ref.watch(catalogRepositoryProvider).actions();
});

/// Emission factors indexed by id, used by [ImpactEngine] at estimation time.
final emissionFactorsProvider =
    FutureProvider<Map<String, EmissionFactor>>((ref) {
  return ref.watch(catalogRepositoryProvider).factors();
});

/// Diary writer. Overridden in widget tests with an in-memory fake.
final actionLogRepositoryProvider =
    FutureProvider<ActionLogRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ActionLogRepository(db);
});

/// Chart data for the Impact tab. Invalidated after each logged action.
final impactProvider = FutureProvider<ImpactSummary>((ref) async {
  final repository = await ref.watch(actionLogRepositoryProvider.future);
  return computeImpactSummary(repository, DateTime.now());
});

/// Challenges, streaks and badges. Invalidated after each logged action so
/// newly-satisfied badges get awarded and progress moves.
final challengesProvider = FutureProvider<ChallengesSnapshot>((ref) async {
  final catalog = ref.watch(catalogRepositoryProvider);
  final db = await ref.watch(databaseProvider.future);
  return computeChallengesSnapshot(
    challenges: await catalog.challenges(),
    badges: await catalog.badges(),
    logs: await ref.watch(actionLogRepositoryProvider.future),
    badgeRepo: BadgeRepository(db),
    now: DateTime.now(),
  );
});

/// Demo community leaderboard, built from the user's real totals plus seeded
/// peers. During onboarding-refresh it may briefly fall back to zeroes.
final communityProvider = FutureProvider<CommunitySnapshot>((ref) async {
  final stats = await ref.watch(dashboardStatsProvider.future);
  return computeCommunitySnapshot(
    source: const DemoCommunityDataSource(),
    totalKg: stats.totalKg,
    totalActions: stats.totalActions,
  );
});

/// Coach implementation. Offline and deterministic; override in tests.
final coachServiceProvider =
    Provider<CoachService>((ref) => const RulesCoach());

/// Daily reminder scheduler. Uses the device plugin in production; override
/// in tests to avoid platform channels.
final reminderSchedulerProvider = FutureProvider<ReminderScheduler>((ref) {
  return LocalReminderScheduler.create();
});

/// Full-database backup/restore, used by Settings → Data management.
final dataPortProvider = FutureProvider<DataPortService>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DataPortService(
    profile: ProfileRepository(db),
    actionLogs: ActionLogRepository(db),
    badges: BadgeRepository(db),
    challengeProgress: ChallengeProgressRepository(db),
  );
});

/// What the coach knows about this user right now.
final coachContextProvider = FutureProvider<CoachContext>((ref) async {
  final profile = (await ref.watch(profileProvider.future))!;
  final stats = await ref.watch(dashboardStatsProvider.future);
  return CoachContext(
    profile: profile,
    categories: profile.interests,
    totalKg: stats.totalKg,
    totalActions: stats.totalActions,
    currentStreak: stats.currentStreak,
    habits: profile.habits,
    preferredActions: stats.todayLogs.map((log) => log.actionTitle).toList(),
  );
});
