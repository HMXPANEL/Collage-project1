import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/action_log_repository.dart';
import 'package:eco_action/data/repositories/badge_repository.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/domain/models/badge.dart';
import 'package:eco_action/domain/models/challenge.dart';
import 'package:eco_action/features/challenges/progress_engine.dart';
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

  const now = DateTime(2026, 8, 11, 14);

  const greenWeek = Challenge(
    id: 'green_week',
    title: 'Green Week',
    description: '10 eco actions in 7 days',
    icon: 'green_week',
    rule: ChallengeRule(
      type: ChallengeRuleType.countActions,
      target: 10,
      windowDays: 7,
    ),
  );
  const noPlasticWeek = Challenge(
    id: 'no_plastic_week',
    title: 'No Plastic Week',
    description: '3 waste actions this week',
    icon: 'no_plastic',
    rule: ChallengeRule(
      type: ChallengeRuleType.countCategoryActions,
      category: 'waste',
      target: 3,
      windowDays: 7,
    ),
  );

  ActionLog log(String id, String category, DateTime happenedOn) => ActionLog(
        actionId: id,
        actionTitle: id,
        category: category,
        happenedOn: happenedOn,
        kgCo2e: 0.1,
      );

  group('computeChallengeProgresses', () {
    test('counts qualifying entries inside the window only', () async {
      final repository = ActionLogRepository(db);
      // Waste actions inside the 7-day window: today + 4 days ago.
      await repository.add(log('a', 'waste', DateTime(2026, 8, 11, 9)));
      await repository.add(log('b', 'waste', DateTime(2026, 8, 7, 9)));
      // Waste action just outside the window (8 days ago).
      await repository.add(log('c', 'waste', DateTime(2026, 8, 3, 9)));
      // Transport actions inside, next-day edge excluded for countActions too.
      await repository.add(log('d', 'transport', DateTime(2026, 8, 11, 10)));

      final progresses = await computeChallengeProgresses(
        const [greenWeek, noPlasticWeek],
        repository,
        now,
      );

      expect(progresses, hasLength(2));

      final green = progresses[0];
      expect(green.challenge.id, 'green_week');
      // 3 total in window (2 waste + 1 transport).
      expect(green.progress, 3);
      expect(green.target, 10);
      expect(green.completed, isFalse);
      expect(green.fraction, closeTo(0.3, 0.0001));

      final waste = progresses[1];
      expect(waste.progress, 2);
      expect(waste.completed, isFalse);

      // Crossing the target marks the challenge complete.
      for (var i = 0; i < 3; i++) {
        await repository.add(
          log('w$i', 'waste', DateTime(2026, 8, 9, 12)),
        );
      }
      final done = (await computeChallengeProgresses(
        const [noPlasticWeek],
        repository,
        now,
      ))
          .single;
      expect(done.progress, 5);
      expect(done.completed, isTrue);
      expect(done.fraction, 1.0);
    });
  });

  group('badgesToAward', () {
    const badges = [
      Badge(
        id: 'first_step',
        title: 'First Step',
        description: 'One action',
        icon: 'first_step',
        condition: BadgeCondition(
          type: BadgeConditionType.countTotal,
          value: 1,
        ),
      ),
      Badge(
        id: 'streak_7',
        title: 'Week Warrior',
        description: '7 day streak',
        icon: 'streak_7',
        condition: BadgeCondition(
          type: BadgeConditionType.bestStreak,
          value: 7,
        ),
      ),
      Badge(
        id: 'challenge_done',
        title: 'Challenge Champion',
        description: 'One challenge done',
        icon: 'challenge_done',
        condition: BadgeCondition(
          type: BadgeConditionType.challengeCompleted,
          value: 1,
        ),
      ),
    ];

    test('awards satisfied conditions and skips already-earned', () {
      final toAward = badgesToAward(
        badges,
        totalActions: 3,
        bestStreak: 8,
        challengesCompleted: 1,
        alreadyEarned: const {'first_step'},
      );
      // streak_7 and challenge_done satisfied; first_step skipped as earned.
      expect(toAward, ['streak_7', 'challenge_done']);
    });

    test('awards nothing when all conditions unmet', () {
      expect(
        badgesToAward(
          badges,
          totalActions: 0,
          bestStreak: 0,
          challengesCompleted: 0,
          alreadyEarned: const {},
        ),
        isEmpty,
      );
    });
  });

  group('computeChallengesSnapshot', () {
    test('computes progress, awards badges and reports streak', () async {
      final repository = ActionLogRepository(db);
      final badgeRepository = BadgeRepository(db);

      // 8 actions in window across 2 days, enough to finish the waste
      // challenge and satisfy first_step.
      for (var i = 0; i < 4; i++) {
        await repository.add(
          log('w$i', 'waste', DateTime(2026, 8, 11, 9 + i)),
        );
        await repository.add(
          log('t$i', 'transport', DateTime(2026, 8, 10, 9 + i)),
        );
      }

      final snapshot = await computeChallengesSnapshot(
        challenges: const [noPlasticWeek],
        badges: const [
          Badge(
            id: 'first_step',
            title: 'First Step',
            description: 'One action',
            icon: 'first_step',
            condition: BadgeCondition(
              type: BadgeConditionType.countTotal,
              value: 1,
            ),
          ),
          Badge(
            id: 'challenge_done',
            title: 'Challenge Champion',
            description: 'One challenge done',
            icon: 'challenge_done',
            condition: BadgeCondition(
              type: BadgeConditionType.challengeCompleted,
              value: 1,
            ),
          ),
        ],
        logs: repository,
        badgeRepo: badgeRepository,
        now: now,
      );

      // Waste challenge: 4 waste entries in window, target 3.
      expect(snapshot.challenges.single.progress, 4);
      expect(snapshot.challenges.single.completed, isTrue);
      // Two consecutive days log actions -> current streak 2, best 2.
      expect(snapshot.currentStreak, 2);
      // first_step (8 total) and challenge_done awarded and persisted.
      expect(snapshot.isEarned('first_step'), isTrue);
      expect(snapshot.isEarned('challenge_done'), isTrue);
      expect(await badgeRepository.has('first_step'), isTrue);
      expect(await badgeRepository.has('challenge_done'), isTrue);
    });

    test('does not re-award already earned badges', () async {
      final repository = ActionLogRepository(db);
      final badgeRepository = BadgeRepository(db);
      await badgeRepository.award('first_step');

      const badges = [
        Badge(
          id: 'first_step',
          title: 'First Step',
          description: 'One action',
          icon: 'first_step',
          condition: BadgeCondition(
            type: BadgeConditionType.countTotal,
            value: 1,
          ),
        ),
      ];
      await repository.add(log('a', 'waste', DateTime(2026, 8, 11, 9)));

      final snapshot = await computeChallengesSnapshot(
        challenges: const [],
        badges: badges,
        logs: repository,
        badgeRepo: badgeRepository,
        now: now,
      );

      expect(snapshot.isEarned('first_step'), isTrue);
      // earned() still returns just the single id (no duplicate rows).
      expect(await badgeRepository.earned(), ['first_step']);
    });
  });
}