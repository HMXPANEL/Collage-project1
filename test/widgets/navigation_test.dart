import 'package:eco_action/app.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_test_harness.dart';

void main() {
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
        overrides: profileOverrides(repository),
        child: const EcoActionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find
          .text("Dashboard and today's actions arrive in Phase 5.")
          .hitTestable(),
      findsOneWidget,
    );

    await tester.tap(tab('Impact'));
    await tester.pumpAndSettle();
    expect(
      find.text('Impact history and charts arrive in Phase 7.').hitTestable(),
      findsOneWidget,
    );
    expect(
      find
          .text("Dashboard and today's actions arrive in Phase 5.")
          .hitTestable(),
      findsNothing,
    );

    await tester.tap(tab('Actions'));
    await tester.pumpAndSettle();
    expect(
      find.text('The action catalog arrives in Phase 6.').hitTestable(),
      findsOneWidget,
    );

    await tester.tap(tab('Challenges'));
    await tester.pumpAndSettle();
    expect(
      find
          .text('Challenges, streaks and badges arrive in Phase 8.')
          .hitTestable(),
      findsOneWidget,
    );

    await tester.tap(tab('Profile'));
    await tester.pumpAndSettle();
    expect(
      find
          .text('Profile, settings and your coach arrive in later phases.')
          .hitTestable(),
      findsOneWidget,
    );
  });
}
