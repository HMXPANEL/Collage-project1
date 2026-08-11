import 'package:eco_action/app.dart';
import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/domain/models/eco_action.dart';
import 'package:eco_action/domain/models/emission_factor.dart';
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

  Widget app(
    MemoryProfileRepository repository, {
    required DashboardStats stats,
    List<EcoAction> actions = const [],
    Map<String, EmissionFactor> factors = const {},
  }) {
    return ProviderScope(
      overrides: [
        ...profileOverrides(repository),
        dashboardStatsProvider.overrideWith((ref) async => stats),
        ...catalogOverrides(actions: actions, factors: factors),
      ],
      child: const EcoActionApp(),
    );
  }

  testWidgets('home shows lifetime stats and today tiles', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final stats = DashboardStats(
      totalKg: 0.89,
      totalActions: 2,
      currentStreak: 2,
      bestStreak: 4,
      todayLogs: [
        ActionLog(
          actionId: 'walk_short_route',
          actionTitle: 'Walk',
          category: 'transport',
          happenedOn: DateTime(2026, 8, 11, 9),
          kgCo2e: 0.85,
        ),
        ActionLog(
          actionId: 'reuse_bottle',
          actionTitle: 'Bottle',
          category: 'waste',
          happenedOn: DateTime(2026, 8, 11, 10),
          kgCo2e: 0.04,
        ),
      ],
      todayKg: 0.89,
    );

    await tester.pumpWidget(app(
      MemoryProfileRepository(
        profile: const UserProfile(
          region: 'in',
          transportBaseline: 'scooter',
          onboarded: true,
        ),
      ),
      stats: stats,
    ));
    await tester.pumpAndSettle();

    expect(find.text('0.89 kg'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('Walk').hitTestable(), findsOneWidget);
    expect(find.text('Bottle').hitTestable(), findsOneWidget);
  });

  testWidgets('home shows empty state when no actions are logged',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const stats = DashboardStats(
      totalKg: 0,
      totalActions: 0,
      currentStreak: 0,
      bestStreak: 0,
      todayLogs: [],
      todayKg: 0,
    );

    await tester.pumpWidget(app(
      MemoryProfileRepository(
        profile: const UserProfile(
          region: 'in',
          transportBaseline: 'scooter',
          onboarded: true,
        ),
      ),
      stats: stats,
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
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nothing logged yet today.'), findsOneWidget);

    final browse = find.widgetWithText(FilledButton, 'Browse actions');
    expect(browse, findsOneWidget);
    await tester.tap(browse);
    await tester.pumpAndSettle();

    // Browse lands on the actions tab.
    expect(
      find.text('Use a reusable bottle').hitTestable(),
      findsOneWidget,
    );
  });
}
