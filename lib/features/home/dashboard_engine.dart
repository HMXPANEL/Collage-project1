import 'package:flutter/foundation.dart';

import '../../core/dates.dart';
import '../../data/repositories/action_log_repository.dart';
import '../../domain/models/action_log.dart';
import 'streak_engine.dart';

/// Everything the home dashboard shows, computed from the action log.
@immutable
class DashboardStats {
  const DashboardStats({
    required this.totalKg,
    required this.totalActions,
    required this.currentStreak,
    required this.bestStreak,
    required this.todayLogs,
    required this.todayKg,
  });

  final double totalKg;
  final int totalActions;
  final int currentStreak;
  final int bestStreak;
  final List<ActionLog> todayLogs;
  final double todayKg;

  bool get hasAnyActivity => totalActions > 0;
}

/// Reads the diary through SQL aggregates and [StreakEngine].
Future<DashboardStats> computeDashboardStats(
  ActionLogRepository repository,
  DateTime now,
) async {
  final today = dateOnly(now);
  final dayAfterToday = nextDay(today);
  final startOfTime = DateTime.fromMillisecondsSinceEpoch(0);

  final totalKg = await repository.sumKgBetween(startOfTime, dayAfterToday);
  final totalActions =
      await repository.countBetween(startOfTime, dayAfterToday);
  final days =
      await repository.distinctDatesBetween(startOfTime, dayAfterToday);
  final todayLogs = await repository.between(today, dayAfterToday);
  final todayKg = todayLogs.fold(0.0, (sum, log) => sum + log.kgCo2e);

  return DashboardStats(
    totalKg: totalKg,
    totalActions: totalActions,
    currentStreak: StreakEngine().currentStreak(days, today),
    bestStreak: StreakEngine().bestStreak(days),
    todayLogs: todayLogs,
    todayKg: todayKg,
  );
}