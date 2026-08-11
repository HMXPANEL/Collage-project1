import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:eco_action/features/settings/reminder_scheduler.dart';
import 'package:eco_action/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('settings screen shows appearance, reminders and data options',
      (tester) async {
    final repository = MemoryProfileRepository(
      profile: const UserProfile(
        region: 'in',
        transportBaseline: 'scooter',
        onboarded: true,
        reminderMinutesFromMidnight: 7 * 60 + 30,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...profileOverrides(repository),
          reminderSchedulerProvider.overrideWith(
            (ref) async => _NoopScheduler(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.textContaining('07:30 AM'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Export my data'), 200);
    expect(find.text('Export my data'), findsOneWidget);
    expect(find.text('Delete all data'), findsOneWidget);
  });
}

class _NoopScheduler implements ReminderScheduler {
  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleDaily({
    required int hourOfDay,
    required int minute,
    required String title,
    required String body,
  }) async {}
}
