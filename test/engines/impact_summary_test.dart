import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/action_log_repository.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/features/impact/impact_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabaseSchema.version,
        onCreate: AppDatabaseSchema.create,
      ),
    );
  });
  tearDown(() async {
    await db.close();
  });

  test('aggregates totals, the 7-day window and categories', () async {
    final repository = ActionLogRepository(db);
    final now = DateTime(2026, 8, 11, 14);

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
        happenedOn: DateTime(2026, 8, 10, 10),
        kgCo2e: 0.04,
      ),
    );
    // Inside the 7-day window, on a day with no other logs.
    await repository.add(
      ActionLog(
        actionId: 'natural_light',
        actionTitle: 'Natural light',
        category: 'energy',
        happenedOn: DateTime(2026, 8, 8, 8),
        kgCo2e: 0.1,
      ),
    );
    // Outside the weekly window but still in lifetime totals.
    await repository.add(
      ActionLog(
        actionId: 'plant_based_meal',
        actionTitle: 'Meal',
        category: 'food',
        happenedOn: DateTime(2026, 8, 4, 12),
        kgCo2e: 2.0,
      ),
    );

    final summary = await computeImpactSummary(repository, now);

    expect(summary.totalKg, closeTo(2.99, 0.0001));
    expect(summary.totalActions, 4);
    // 7 days: 2026-08-05 .. 2026-08-11.
    expect(summary.lastSevenDaysKg, hasLength(7));
    expect(summary.lastSevenDaysKg[0], 0.0); // 08-05
    expect(summary.lastSevenDaysKg[3], closeTo(0.1, 0.0001)); // 08-08
    expect(summary.lastSevenDaysKg[5], closeTo(0.04, 0.0001)); // 08-10
    expect(summary.lastSevenDaysKg[6], closeTo(0.85, 0.0001)); // 08-11
    expect(summary.categoryKg['transport'], closeTo(0.85, 0.0001));
    expect(summary.categoryKg['waste'], closeTo(0.04, 0.0001));
    expect(summary.categoryKg['energy'], closeTo(0.1, 0.0001));
    expect(summary.categoryKg['food'], closeTo(2.0, 0.0001));
    expect(summary.categoryKg['water'], isNull);
  });

  test('an empty diary yields zeroes over the window', () async {
    final summary = await computeImpactSummary(
      ActionLogRepository(db),
      DateTime(2026, 8, 11, 12),
    );
    expect(summary.totalKg, 0);
    expect(summary.totalActions, 0);
    expect(summary.lastSevenDaysKg, everyElement(0.0));
    expect(summary.categoryKg, isEmpty);
  });
}
