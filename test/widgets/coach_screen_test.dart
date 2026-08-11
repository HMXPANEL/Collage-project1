import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:eco_action/features/coach/coach_engine.dart';
import 'package:eco_action/features/coach/coach_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_test_harness.dart';

void main() {
  testWidgets('coach screen replies with a rule-based answer offline',
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
          coachServiceProvider.overrideWith(
            (ref) => _GreetingCoach(),
          ),
        ],
        child: const MaterialApp(home: CoachScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'what should i do?',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('greetings, offline friend'), findsOneWidget);
  });
}

class _GreetingCoach implements CoachService {
  @override
  CoachReply reply(String prompt, CoachContext context) {
    return const CoachReply(message: 'greetings, offline friend');
  }
}
