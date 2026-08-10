import 'package:eco_action/app.dart';
import 'package:eco_action/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/app_test_harness.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await openTestDatabase();
  });
  tearDown(() async {
    await db.close();
  });

  testWidgets('onboarding flow collects answers, saves profile, lands on home',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: appOverrides(db), child: const EcoActionApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('EcoAction'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('How do you usually travel?'), findsOneWidget);
    await tester.tap(find.text('Scooter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What interests you most?'), findsOneWidget);
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Which habits sound like you?'), findsOneWidget);
    await tester.tap(find.text('I recycle waste at home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('You are all set'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    final profile = await ProfileRepository(db).get();
    expect(profile, isNotNull);
    expect(profile!.onboarded, isTrue);
    expect(profile.transportBaseline, 'scooter');
    expect(profile.dailyCommuteKm, 8.0);
    expect(profile.interests, containsAll(['transport', 'waste']));
    expect(profile.habits['recycling'], 'yes');

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find
          .text("Dashboard and today's actions arrive in Phase 5.")
          .hitTestable(),
      findsOneWidget,
    );
  });
}
