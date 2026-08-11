import 'package:eco_action/app.dart';
import 'package:eco_action/core/state/providers.dart';
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

  const factors = {
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
    'petrol_car_km': EmissionFactor(
      id: 'petrol_car_km',
      value: 0.19,
      unit: 'km',
      category: EmissionCategory.transport,
      region: 'global',
      version: 'v1',
      sourceName: 'test',
      sourceReference: 'test',
      notes: 'test',
      kind: EmissionFactorKind.emission,
    ),
    'walking_km': EmissionFactor(
      id: 'walking_km',
      value: 0.0,
      unit: 'km',
      category: EmissionCategory.transport,
      region: 'global',
      version: 'v1',
      sourceName: 'test',
      sourceReference: 'test',
      notes: 'test',
      kind: EmissionFactorKind.emission,
    ),
  };

  const actions = [
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
    EcoAction(
      id: 'walk_short_route',
      title: 'Walk instead of taking a vehicle',
      description: 'Pick walking for short trips.',
      whyItHelps: 'Cuts vehicle emissions to zero.',
      category: EmissionCategory.transport,
      icon: 'walk',
      impact: ActionImpactSpec.baselineAlternative(
        baselineFactorId: 'petrol_car_km',
        alternativeFactorId: 'walking_km',
        quantityUnit: 'km',
        quantityLabel: 'Distance you walked (km)',
      ),
    ),
  ];

  Widget app(MemoryActionLogRepository logs) {
    return ProviderScope(
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
          actions: actions,
          factors: factors,
          actionLogs: logs,
        ),
      ],
      child: const EcoActionApp(),
    );
  }

  Finder actionsTab() => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Actions'),
      );

  testWidgets('catalog lists actions grouped by category with estimates',
      (tester) async {
    await tester.pumpWidget(app(MemoryActionLogRepository()));
    await tester.pumpAndSettle();

    await tester.tap(actionsTab());
    await tester.pumpAndSettle();

    expect(find.text('Take Action'), findsOneWidget);
    expect(find.text('Waste'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Use a reusable bottle'), findsOneWidget);
    expect(find.text('Walk instead of taking a vehicle'), findsOneWidget);
    expect(find.text('~0.50 kg'), findsOneWidget);
    expect(find.text('~0.19 kg'), findsOneWidget);
  });

  testWidgets('logging an action records the estimate and returns to the list',
      (tester) async {
    final logs = MemoryActionLogRepository();
    await tester.pumpWidget(app(logs));
    await tester.pumpAndSettle();

    await tester.tap(actionsTab());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use a reusable bottle'));
    await tester.pumpAndSettle();

    expect(find.text('Times you refilled'), findsOneWidget);
    expect(find.text('~0.50 kg'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      '2',
    );
    await tester.pumpAndSettle();
    expect(find.text('~1.00 kg'), findsOneWidget);

    await tester.tap(find.text('Log this action'));
    await tester.pumpAndSettle();

    expect(logs.logs, hasLength(1));
    final log = logs.logs.single;
    expect(log.actionId, 'reuse_bottle');
    expect(log.category, 'waste');
    expect(log.kgCo2e, closeTo(1.0, 0.0001));
    expect(log.quantity, closeTo(2.0, 0.0001));
    expect(log.inputUnit, 'use');
    expect(log.provisional, isFalse);

    expect(find.text('Logged ~1.00 kg CO₂e'), findsOneWidget);
    // Back on the catalog list.
    expect(find.text('Walk instead of taking a vehicle'), findsOneWidget);
  });

  testWidgets('zero quantity is rejected and nothing is logged',
      (tester) async {
    final logs = MemoryActionLogRepository();
    await tester.pumpWidget(app(logs));
    await tester.pumpAndSettle();

    await tester.tap(actionsTab());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use a reusable bottle'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log this action'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a quantity greater than 0'), findsOneWidget);
    expect(logs.logs, isEmpty);
  });
}
