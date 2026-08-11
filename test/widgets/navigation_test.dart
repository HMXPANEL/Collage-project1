import 'package:eco_action/app.dart';
import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/domain/models/eco_action.dart';
import 'package:eco_action/domain/models/emission_factor.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:eco_action/features/challenges/progress_engine.dart';
import 'package:eco_action/features/home/dashboard_engine.dart';
import 'package:eco_action/features/impact/impact_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_test_harness.dart';

void main() {
  const _emptySnapshot = ChallengesSnapshot(
    currentStreak: 0,
    challenges: [],
    badges: [],
    earnedBadgeIds: {},
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  testWidgets('bottom navigation switches between all five tabs',
      (tester) async {
    final repository = MemoryProfileRepository(
      profile: const UserProfile(
        region: 'in',
        transportBaseline: 'scooter',
        onboarded: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...profileOverrides(repository),
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
          impactProvider.overrideWith(
            (ref) async => const ImpactSummary(
              totalKg: 0,
              totalActions: 0,
              lastSevenDaysKg: [0, 0, 0, 0, 0, 0, 0],
              categoryKg: {},
            ),
          ),
          challengesProvider.overrideWith((ref) async => _emptySnapshot),
          ...catalogOverrides(
            actions: const [
              EcoAction(
                id: 'reuse_bottle',
                title: 'Use a reusable bottle',
                description: 'Refill instead of buying single-use.',
                whyItHelps: 'Avoids plastic lifecycle emissions.',
                category: EmissionCategory.waste,
                icon: 'bottle',
                impact: ActionImpactSpec.perUnit(
                  factorId: 'reuse_bottle_use',
                  quantityUnit: 'use',
                  quantityLabel: 'Times you refilled',
                ),
              ),
            ],
            factors: const {
              'reuse_bottle_use': EmissionFactor(
                id: 'reuse_bottle_use',
                value: 0.5,
                unit: 'use',
                category: EmissionCategory.waste,
                region: 'global',
                version: 'v1',
                sourceName: 'test',
                sourceReference: 'test',
                notes: 'test',
                kind: EmissionFactorKind.avoidance,
              ),
            },
          ),
        ],
        child: const EcoActionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your climate journey').hitTestable(),
      findsOneWidget,
    );

    await tester.tap(tab('Impact'));
    await tester.pumpAndSettle();
    expect(
      find.text('My Impact').hitTestable(),
      findsOneWidget,
    );
    expect(
      find.text('Your climate journey').hitTestable(),
      findsNothing,
    );

    await tester.tap(tab('Actions'));
    await tester.pumpAndSettle();
    expect(find.text('Take Action').hitTestable(), findsOneWidget);
    expect(
      find.text('Use a reusable bottle').hitTestable(),
      findsOneWidget,
    );

    await tester.tap(tab('Challenges'));
    await tester.pumpAndSettle();
    expect(find.text('Active challenges').hitTestable(), findsOneWidget);
    expect(find.text('Badges').hitTestable(), findsOneWidget);

    await tester.tap(tab('Profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('Climate Coach').hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Community leaderboard').hitTestable(), findsOneWidget);
  });
}
