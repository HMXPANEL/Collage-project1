import 'package:eco_action/app.dart';
import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/domain/models/badge.dart';
import 'package:eco_action/domain/models/challenge.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:eco_action/features/challenges/progress_engine.dart';
import 'package:eco_action/features/home/dashboard_engine.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const snapshot = ChallengesSnapshot(
    currentStreak: 3,
    challenges: [
      ChallengeWithProgress(
        challenge: Challenge(
          id: 'green_week',
          title: 'Green Week',
          description: '10 eco actions in 7 days',
          icon: 'green_week',
          rule: ChallengeRule(
            type: ChallengeRuleType.countActions,
            target: 10,
            windowDays: 7,
          ),
        ),
        progress: 3,
      ),
      ChallengeWithProgress(
        challenge: Challenge(
          id: 'no_plastic_week',
          title: 'No Plastic Week',
          description: '3 waste actions this week',
          icon: 'no_plastic',
          rule: ChallengeRule(
            type: ChallengeRuleType.countCategoryActions,
            category: 'waste',
            target: 3,
            windowDays: 7,
          ),
        ),
        progress: 3,
      ),
    ],
    badges: [
      Badge(
        id: 'first_step',
        title: 'First Step',
        description: 'One action',
        icon: 'first_step',
        condition: BadgeCondition(
          type: BadgeConditionType.countTotal,
          value: 1,
        ),
      ),
      Badge(
        id: 'streak_7',
        title: 'Week Warrior',
        description: '7 day streak',
        icon: 'streak_7',
        condition: BadgeCondition(
          type: BadgeConditionType.bestStreak,
          value: 7,
        ),
      ),
    ],
    earnedBadgeIds: {'first_step'},
  );

  Future<void> pumpApp(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...profileOverrides(
            MemoryProfileRepository(
              profile: const UserProfile(
                region: 'in',
                transportBaseline: 'scooter',
                onboarded: true,
              ),
            ),
          ),
          dashboardStatsProvider.overrideWith(
            (ref) async => const DashboardStats(
              totalKg: 0,
              totalActions: 0,
              currentStreak: 0,
              bestStreak: 0,
              todayLogs: [],
              todayKg: 0,
            ),
          ),
          challengesProvider.overrideWith((ref) async => snapshot),
          ...catalogOverrides(actions: const [], factors: const {}),
        ],
        child: const EcoActionApp(),
      ),
    );
  }

  testWidgets('challenges tab shows streaks, progress and badges',
      (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Challenges'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('days streak — keep it going!'), findsOneWidget);

    expect(find.text('Green Week'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('No Plastic Week'), findsOneWidget);
    // Completed challenge shows the target, not the current progress.
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Badge collection: earned vs locked.
    expect(find.text('First Step'), findsOneWidget);
    expect(find.text('Week Warrior'), findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('challenges tab handles an empty diary', (tester) async {
    const empty = ChallengesSnapshot(
      currentStreak: 0,
      challenges: [],
      badges: [],
      earnedBadgeIds: {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...profileOverrides(
            MemoryProfileRepository(
              profile: const UserProfile(
                region: 'in',
                transportBaseline: 'scooter',
                onboarded: true,
              ),
            ),
          ),
          dashboardStatsProvider.overrideWith(
            (ref) async => const DashboardStats(
              totalKg: 0,
              totalActions: 0,
              currentStreak: 0,
              bestStreak: 0,
              todayLogs: [],
              todayKg: 0,
            ),
          ),
          challengesProvider.overrideWith((ref) async => empty),
          ...catalogOverrides(actions: const [], factors: const {}),
        ],
        child: const EcoActionApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Challenges'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No streak yet. Log an action to start one.'),
      findsOneWidget,
    );
    expect(find.text('Active challenges'), findsOneWidget);
  });
}
