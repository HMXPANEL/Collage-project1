import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/action_log_repository.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/features/home/dashboard_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('DashboardStats', () {
    test('hasAnyActivity is false when no actions exist', () {
      const stats = DashboardStats(
        totalKg: 0,
        totalActions: 0,
        currentStreak: 0,
        bestStreak: 0,
        todayLogs: [],
        todayKg: 0,
      );
      expect(stats.hasAnyActivity, isFalse);
    });

    test('computeDashboardStats aggregates totals and streaks', () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: AppDatabaseSchema.version,
          onCreate: AppDatabaseSchema.create,
        ),
      );

      final repository = ActionLogRepository(db);
      final now = DateTime(2026, 8, 11, 14);

      // Today: two actions.
      await repository.add(
        ActionLog(
          actionId: 'walk_short_route',
          actionTitle: 'Walk',
          category: 'transport',
          happenedOn: DateTime(2026, 8, 11, 9),
          kgCo2e: 0.85,
        ),
      );
      await repository.add(
        ActionLog(
          actionId: 'reuse_bottle',
          actionTitle: 'Bottle',
          category: 'waste',
          happenedOn: DateTime(2026, 8, 11, 10),
          kgCo2e: 0.04,
        ),
      );
      // Yesterday: one action.
      await repository.add(
        ActionLog(
          actionId: 'led_switch',
          actionTitle: 'LED',
          category: 'energy',
          happenedOn: DateTime(2026, 8, 10, 20),
          kgCo2e: 0.1,
        ),
      );
      // Two days ago: gap, breaks the streak.
      await repository.add(
        ActionLog(
          actionId: 'bike_commute',
          actionTitle: 'Bike',
          category: 'transport',
          happenedOn: DateTime(2026, 8, 8, 8),
          kgCo2e: 1.2,
        ),
      );

      final stats = await computeDashboardStats(repository, now);

      expect(stats.hasAnyActivity, isTrue);
      expect(stats.totalActions, 4);
      expect(stats.totalKg, closeTo(2.19, 0.0001));
      expect(stats.todayLogs, hasLength(2));
      expect(stats.todayKg, closeTo(0.89, 0.0001));
      // Aligned streak covers today and yesterday only.
      expect(stats.currentStreak, 2);
      // Best run is just those two days too.
      expect(stats.bestStreak, 2);
    });

    test('zero streak without yesterday activity', () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: AppDatabaseSchema.version,
          onCreate: AppDatabaseSchema.create,
        ),
      );
      final repository = ActionLogRepository(db);
      await repository.add(
        ActionLog(
          actionId: 'led_switch',
          actionTitle: 'LED',
          category: 'energy',
          happenedOn: DateTime(2026, 8, 9, 20),
          kgCo2e: 0.1,
        ),
      );

      final stats = await computeDashboardStats(
        repository,
        DateTime(2026, 8, 11, 12),
      );

      expect(stats.totalActions, 1);
      expect(stats.todayLogs, isEmpty);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 1);

      await db.close();
    });
  });
}
