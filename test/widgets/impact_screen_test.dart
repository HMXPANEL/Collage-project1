import 'package:eco_action/app.dart';
import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:eco_action/features/home/dashboard_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('impact tab shows totals, the 7-day chart and categories',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final logs = MemoryActionLogRepository();
    await logs.add(
      ActionLog(
        actionId: 'walk_short_route',
        actionTitle: 'Walk',
        category: 'transport',
        happenedOn: now,
        kgCo2e: 0.85,
      ),
    );
    await logs.add(
      ActionLog(
        actionId: 'reuse_bottle',
        actionTitle: 'Bottle',
        category: 'waste',
        happenedOn: now.subtract(const Duration(days: 1)),
        kgCo2e: 0.04,
      ),
    );
    await logs.add(
      ActionLog(
        actionId: 'plant_based_meal',
        actionTitle: 'Meal',
        category: 'food',
        happenedOn: now.subtract(const Duration(days: 3)),
        kgCo2e: 2.0,
      ),
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
          ...catalogOverrides(
            actions: const [],
            factors: const {},
            actionLogs: logs,
          ),
        ],
        child: const EcoActionApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Impact'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Impact'), findsOneWidget);
    expect(find.text('~2.89 kg'), findsOneWidget);
    expect(
      find.text('Total CO₂e avoided · 3 actions'),
      findsOneWidget,
    );
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('By category'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Waste'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('impact tab handles an empty diary', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
          ...catalogOverrides(
            actions: const [],
            factors: const {},
            actionLogs: MemoryActionLogRepository(),
          ),
        ],
        child: const EcoActionApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Impact'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('~0.00 kg'), findsOneWidget);
    expect(
      find.text('Nothing logged yet. Your first action will show up here.'),
      findsOneWidget,
    );
  });
}
