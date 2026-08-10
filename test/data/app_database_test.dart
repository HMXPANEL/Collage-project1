import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/action_log_repository.dart';
import 'package:eco_action/data/repositories/badge_repository.dart';
import 'package:eco_action/data/repositories/challenge_progress_repository.dart';
import 'package:eco_action/data/repositories/profile_repository.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/domain/models/challenge.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<Database> openDb() async {
    return databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabaseSchema.version,
        onCreate: AppDatabaseSchema.create,
      ),
    );
  }

  late Database db;
  setUp(() async {
    db = await openDb();
  });
  tearDown(() async {
    await db.close();
  });

  group('ProfileRepository', () {
    test('returns null before any profile is saved', () async {
      expect(await ProfileRepository(db).get(), isNull);
    });

    test('saves and round-trips a profile', () async {
      final repo = ProfileRepository(db);
      await repo.save(
        const UserProfile(
          region: 'in',
          transportBaseline: 'scooter',
          dailyCommuteKm: 8,
          interests: ['transport', 'waste'],
          habits: {'bottle': 'yes'},
          onboarded: true,
        ),
      );
      final profile = await repo.get();
      expect(profile, isNotNull);
      expect(profile!.region, 'in');
      expect(profile.transportBaseline, 'scooter');
      expect(profile.dailyCommuteKm, 8);
      expect(profile.interests, ['transport', 'waste']);
      expect(profile.habits['bottle'], 'yes');
      expect(profile.onboarded, isTrue);
    });

    test('save updates rather than creating a second row', () async {
      final repo = ProfileRepository(db);
      await repo.save(const UserProfile(region: 'in', onboarded: false));
      await repo.save(const UserProfile(region: 'in', onboarded: true));
      expect(await repo.get(), isNotNull);
      expect((await repo.get())!.onboarded, isTrue);
    });

    test('clear removes the profile', () async {
      final repo = ProfileRepository(db);
      await repo.save(const UserProfile(region: 'in'));
      await repo.clear();
      expect(await repo.get(), isNull);
    });
  });

  group('ActionLogRepository', () {
    final day = DateTime(2026, 8, 10);

    test('add and count are correct', () async {
      final repo = ActionLogRepository(db);
      await repo.add(
        ActionLog(
          actionId: 'walk_short_route',
          actionTitle: 'Walk',
          category: 'transport',
          happenedOn: day,
          kgCo2e: 0.85,
        ),
      );
      await repo.add(
        ActionLog(
          actionId: 'reuse_bottle',
          actionTitle: 'Bottle',
          category: 'waste',
          happenedOn: day.add(const Duration(days: 1)),
          kgCo2e: 0.04,
        ),
      );
      final start = DateTime(2026, 8, 10);
      final end = DateTime(2026, 8, 13);
      expect(await repo.countBetween(start, end), 2);
      expect(await repo.sumKgBetween(start, end), closeTo(0.89, 0.0001));
    });

    test('sum and count over an empty range are zero', () async {
      final repo = ActionLogRepository(db);
      expect(
        await repo.sumKgBetween(DateTime(2020), DateTime(2021)),
        0,
      );
      expect(await repo.countBetween(DateTime(2020), DateTime(2021)), 0);
    });

    test('categorySumBetween groups by category', () async {
      final repo = ActionLogRepository(db);
      await repo.add(
        ActionLog(
          actionId: 'a',
          actionTitle: 'A',
          category: 'transport',
          happenedOn: day,
          kgCo2e: 1.0,
        ),
      );
      await repo.add(
        ActionLog(
          actionId: 'b',
          actionTitle: 'B',
          category: 'waste',
          happenedOn: day,
          kgCo2e: 2.0,
        ),
      );
      final sums = await repo.categorySumBetween(
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 11),
      );
      expect(sums['transport'], closeTo(1.0, 0.0001));
      expect(sums['waste'], closeTo(2.0, 0.0001));
    });

    test('distinctDatesBetween returns one entry per local day', () async {
      final repo = ActionLogRepository(db);
      final dayTime = DateTime(2026, 8, 10, 9, 30);
      await repo.add(
        ActionLog(
          actionId: 'a',
          actionTitle: 'A',
          category: 'waste',
          happenedOn: dayTime,
          kgCo2e: 0.1,
        ),
      );
      await repo.add(
        ActionLog(
          actionId: 'b',
          actionTitle: 'B',
          category: 'waste',
          happenedOn: dayTime.add(const Duration(hours: 2)),
          kgCo2e: 0.2,
        ),
      );
      await repo.add(
        ActionLog(
          actionId: 'c',
          actionTitle: 'C',
          category: 'waste',
          happenedOn: dayTime.add(const Duration(days: 1)),
          kgCo2e: 0.3,
        ),
      );
      final days = await repo.distinctDatesBetween(
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 12),
      );
      expect(days, {DateTime(2026, 8, 10), DateTime(2026, 8, 11)});
    });

    test('between respects the range and orders newest first', () async {
      final repo = ActionLogRepository(db);
      await repo.add(
        ActionLog(
          actionId: 'older',
          actionTitle: 'Older',
          category: 'waste',
          happenedOn: DateTime(2026, 8, 10),
          kgCo2e: 0.1,
        ),
      );
      await repo.add(
        ActionLog(
          actionId: 'newer',
          actionTitle: 'Newer',
          category: 'waste',
          happenedOn: DateTime(2026, 8, 11),
          kgCo2e: 0.2,
        ),
      );
      final logs = await repo.between(
        DateTime(2026, 8, 11),
        DateTime(2026, 8, 12),
      );
      expect(logs, hasLength(1));
      expect(logs.first.actionId, 'newer');
    });

    test('deleteById removes exactly one row', () async {
      final repo = ActionLogRepository(db);
      final id = await repo.add(
        ActionLog(
          actionId: 'a',
          actionTitle: 'A',
          category: 'waste',
          happenedOn: day,
          kgCo2e: 0.1,
        ),
      );
      expect(await repo.deleteById(id), 1);
      expect(
        await repo.countBetween(
          DateTime(2026, 8, 10),
          DateTime(2026, 8, 11),
        ),
        0,
      );
    });

    test('wipe deletes everything', () async {
      final repo = ActionLogRepository(db);
      await repo.add(
        ActionLog(
          actionId: 'a',
          actionTitle: 'A',
          category: 'waste',
          happenedOn: day,
          kgCo2e: 0.1,
        ),
      );
      await repo.wipe();
      expect(
        await repo.countBetween(
          DateTime(2026, 8, 10),
          DateTime(2026, 8, 11),
        ),
        0,
      );
    });
  });

  group('ChallengeProgressRepository', () {
    test('setAmount upserts per challenge/day and total sums', () async {
      final repo = ChallengeProgressRepository(db);
      await repo.setAmount('green_week', DateTime(2026, 8, 10), 1);
      await repo.setAmount('green_week', DateTime(2026, 8, 11), 1);
      await repo.setAmount('green_week', DateTime(2026, 8, 11), 1);
      expect(await repo.total('green_week'), 3);
      expect(await repo.forChallenge('green_week'), hasLength(2));
      expect(await repo.total('other'), 0);
    });
  });

  group('BadgeRepository', () {
    test('award is idempotent and earned() returns badges in order', () async {
      final repo = BadgeRepository(db);
      await repo.award('first_step');
      await repo.award('first_step');
      await repo.award('actions_25');
      expect(await repo.has('first_step'), isTrue);
      expect(await repo.has('nope'), isFalse);
      expect(await repo.earned(), ['first_step', 'actions_25']);
    });
  });

  group('ChallengeProgress model', () {
    test('fromRow round-trips a row', () {
      final progress = ChallengeProgress.fromRow({
        'id': 1,
        'challenge_id': 'green_week',
        'date_day': DateTime(2026, 8, 10).millisecondsSinceEpoch,
        'amount': 2.0,
      });
      expect(progress.challengeId, 'green_week');
      expect(progress.dateDay, DateTime(2026, 8, 10));
      expect(progress.amount, 2.0);
    });
  });
}