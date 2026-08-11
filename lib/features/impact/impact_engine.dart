import 'package:flutter/foundation.dart';

import '../../core/dates.dart';
import '../../data/repositories/action_log_repository.dart';

/// Aggregations shown on the Impact tab.
@immutable
class ImpactSummary {
  const ImpactSummary({
    required this.totalKg,
    required this.totalActions,
    required this.lastSevenDaysKg,
    required this.categoryKg,
  });

  final double totalKg;
  final int totalActions;

  /// Daily kg avoided for the last 7 calendar days (earliest first), including
  /// days with no activity (0.0).
  final List<double> lastSevenDaysKg;

  /// Total kg avoided grouped by category name.
  final Map<String, double> categoryKg;
}

/// Reads the diary and groups by local day and category in Dart. The weekly
/// window is small, so loading it and grouping in memory beats timezone-aware
/// SQL date functions.
Future<ImpactSummary> computeImpactSummary(
  ActionLogRepository repository,
  DateTime now,
) async {
  final today = dateOnly(now);
  final weekStart = today.subtract(const Duration(days: 6));
  final endExclusive = nextDay(today);
  final startOfTime = DateTime.fromMillisecondsSinceEpoch(0);

  final daily = <double>[];
  final weekLogs = await repository.between(weekStart, endExclusive);
  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    var kg = 0.0;
    for (final log in weekLogs) {
      if (!log.happenedOn.isBefore(day) &&
          log.happenedOn.isBefore(nextDay(day))) {
        kg += log.kgCo2e;
      }
    }
    daily.add(kg);
  }

  final totalKg = await repository.sumKgBetween(startOfTime, endExclusive);
  final totalActions = await repository.countBetween(startOfTime, endExclusive);
  final categoryKg =
      await repository.categorySumBetween(startOfTime, endExclusive);

  return ImpactSummary(
    totalKg: totalKg,
    totalActions: totalActions,
    lastSevenDaysKg: daily,
    categoryKg: categoryKg,
  );
}
