import 'package:flutter/foundation.dart';

import '../../core/dates.dart';
import '../../data/repositories/action_log_repository.dart';
import '../../data/repositories/badge_repository.dart';
import '../../domain/engines/streak_engine.dart';
import '../../domain/models/badge.dart';
import '../../domain/models/challenge.dart';

/// A challenge alongside its progress over the rolling [windowDays] window.
@immutable
class ChallengeWithProgress {
  const ChallengeWithProgress({
    required this.challenge,
    required this.progress,
  });

  final Challenge challenge;
  final int progress;

  int get target => challenge.rule.target;
  bool get completed => progress >= target;
  double get fraction {
    if (target <= 0) return 0.0;
    return (progress / target).clamp(0.0, 1.0).toDouble();
  }
}

/// Everything the Challenges tab shows.
@immutable
class ChallengesSnapshot {
  const ChallengesSnapshot({
    required this.currentStreak,
    required this.challenges,
    required this.badges,
    required this.earnedBadgeIds,
  });

  final int currentStreak;
  final List<ChallengeWithProgress> challenges;

  /// All badges from the catalog; earned state lives in [earnedBadgeIds].
  final List<Badge> badges;
  final Set<String> earnedBadgeIds;

  bool isEarned(String badgeId) => earnedBadgeIds.contains(badgeId);
}

/// Progress for each challenge, counting qualifying diary entries within the
/// challenge's rolling window. The window is small, so entries are loaded and
/// filtered in Dart.
Future<List<ChallengeWithProgress>> computeChallengeProgresses(
  List<Challenge> challenges,
  ActionLogRepository logs,
  DateTime now,
) async {
  final today = dateOnly(now);
  final endExclusive = nextDay(today);

  final progresses = <ChallengeWithProgress>[];
  for (final challenge in challenges) {
    final windowStart = today.subtract(
      Duration(days: challenge.rule.windowDays - 1),
    );
    final entries = await logs.between(windowStart, endExclusive);
    var count = 0;
    for (final entry in entries) {
      if (challenge.rule.type == ChallengeRuleType.countCategoryActions &&
          entry.category != challenge.rule.category) {
        continue;
      }
      count++;
    }
    progresses.add(
      ChallengeWithProgress(challenge: challenge, progress: count),
    );
  }
  return progresses;
}

/// Badges whose conditions are now satisfied and have not been awarded yet.
List<String> badgesToAward(
  List<Badge> badges, {
  required int totalActions,
  required int bestStreak,
  required int challengesCompleted,
  required Set<String> alreadyEarned,
}) {
  final toAward = <String>[];
  for (final badge in badges) {
    if (alreadyEarned.contains(badge.id)) continue;
    final satisfied = switch (badge.condition.type) {
      BadgeConditionType.countTotal => totalActions >= badge.condition.value,
      BadgeConditionType.bestStreak => bestStreak >= badge.condition.value,
      BadgeConditionType.challengeCompleted =>
        challengesCompleted >= badge.condition.value,
    };
    if (satisfied) toAward.add(badge.id);
  }
  return toAward;
}

/// Computes challenge progress, evaluates badges against the diary, awards
/// any newly earned ones, and returns the snapshot for the screen.
Future<ChallengesSnapshot> computeChallengesSnapshot({
  required List<Challenge> challenges,
  required List<Badge> badges,
  required ActionLogRepository logs,
  required BadgeRepository badgeRepo,
  required DateTime now,
}) async {
  final progresses = await computeChallengeProgresses(challenges, logs, now);

  final startOfTime = DateTime.fromMillisecondsSinceEpoch(0);
  final endExclusive = nextDay(dateOnly(now));
  final totalActions = await logs.countBetween(startOfTime, endExclusive);
  final days = await logs.distinctDatesBetween(startOfTime, endExclusive);
  final streakEngine = const StreakEngine();
  final bestStreak = streakEngine.bestStreak(days);
  final currentStreak = streakEngine.currentStreak(days, now);
  final challengesCompleted = progresses.where((p) => p.completed).length;

  final earnedIds = (await badgeRepo.earned()).toSet();
  for (final id in badgesToAward(
    badges,
    totalActions: totalActions,
    bestStreak: bestStreak,
    challengesCompleted: challengesCompleted,
    alreadyEarned: earnedIds,
  )) {
    await badgeRepo.award(id);
  }

  return ChallengesSnapshot(
    currentStreak: currentStreak,
    challenges: progresses,
    badges: badges,
    earnedBadgeIds: (await badgeRepo.earned()).toSet(),
  );
}
