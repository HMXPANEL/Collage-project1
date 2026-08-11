import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/features/community/community_screen.dart';
import 'package:eco_action/features/home/dashboard_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('community screen renders demo notice and the user rank',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardStatsProvider.overrideWith(
            (ref) async => const DashboardStats(
              totalKg: 150,
              totalActions: 60,
              currentStreak: 2,
              bestStreak: 5,
              todayLogs: [],
              todayKg: 0,
            ),
          ),
        ],
        child: const MaterialApp(home: CommunityScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Demo data'), findsOneWidget);
    expect(find.textContaining('150.0 kg'), findsWidgets);
    expect(find.textContaining('You (demo)'), findsOneWidget);
  });
}