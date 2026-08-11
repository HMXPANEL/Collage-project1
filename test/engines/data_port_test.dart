import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/action_log_repository.dart';
import 'package:eco_action/data/repositories/badge_repository.dart';
import 'package:eco_action/data/repositories/challenge_progress_repository.dart';
import 'package:eco_action/data/repositories/profile_repository.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:eco_action/features/settings/data_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_test_harness.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  DataPortService service() => DataPortService(
        profile: ProfileRepository(db),
        actionLogs: ActionLogRepository(db),
        badges: BadgeRepository(db),
        challengeProgress: ChallengeProgressRepository(db),
      );

  test('export captures profile, logs, badges and challenge progress',
      () async {
    await ProfileRepository(db).save(const UserProfile(
      region: 'in',
      transportBaseline: 'cycle',
      onboarded: true,
    ));
    await BadgeRepository(db).award('first_action');
    await ActionLogRepository(db).add(const ActionLog(
      actionId: 'led_bulb',
      actionTitle: 'Swap to LED bulbs',
      category: 'energy',
      happenedOn: DateTime(2026, 8, 11),
      kgCo2e: 1.2,
    ));
    await ChallengeProgressRepository(db).setAmount(
      'challenge_week_one',
      DateTime(2026, 8, 11),
      3,
    );

    final payload = await service().exportAll();

    expect(payload.version, DataPortService.currentVersion);
    expect(payload.profile!.region, 'in');
    expect(payload.logs.single.actionTitle, 'Swap to LED bulbs');
    expect(payload.badges, ['first_action']);
    expect(payload.challengeProgress.single.amount, 3);

    final json = DataPortService.encode(payload);
    final roundTrip =
        BackupPayload.fromJson(DataPortService.decode(json));
    expect(roundTrip.logs.single.kgCo2e, 1.2);
    expect(roundTrip.badges, ['first_action']);
  });

  test('import restores data into an empty database', () async {
    await ProfileRepository(db).save(const UserProfile(
      region: 'in',
      transportBaseline: 'cycle',
      onboarded: true,
    ));
    await BadgeRepository(db).award('first_action');
    await ActionLogRepository(db).add(const ActionLog(
      actionId: 'led_bulb',
      actionTitle: 'Swap to LED bulbs',
      category: 'energy',
      happenedOn: DateTime(2026, 8, 11),
      kgCo2e: 1.2,
    ));

    final payload = await service().exportAll();
    await service().wipeAll();

    await service().import(payload);

    final profile = await ProfileRepository(db).get();
    expect(profile, isNotNull);
    expect(profile!.region, 'in');
    expect((await BadgeRepository(db).earned()), ['first_action']);
    final end = DateTime.fromMillisecondsSinceEpoch(0x7fffffffffffffff);
    final logs = await ActionLogRepository(db).between(
      DateTime.fromMillisecondsSinceEpoch(0),
      end,
    );
    expect(logs.single.actionId, 'led_bulb');
  });

  test('import rejects unknown version', () async {
    final payload = BackupPayload(
      version: 99,
      exportedAt: '',
      profile: null,
      logs: const [],
      badges: const [],
      challengeProgress: const [],
    );
    await expectLater(
      service().import(payload),
      throwsA(isA<FormatException>()),
    );
  });

  test('wipeAll clears every table', () async {
    await ProfileRepository(db).save(const UserProfile(
      region: 'in',
      onboarded: true,
    ));
    await BadgeRepository(db).award('first_action');

    await service().wipeAll();

    expect(await ProfileRepository(db).get(), isNull);
    expect(await BadgeRepository(db).earned(), isEmpty);
  });
}