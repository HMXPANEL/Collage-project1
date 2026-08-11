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
    this.dailyKg = const [],
    required this.categoryKg,
  });

  final double totalKg;
  final int totalActions;

  /// Daily kg avoided for the last 7 calendar days (earliest first), including
  /// days with no activity (0.0).
  final List<double> lastSevenDaysKg;

  /// Daily kg avoided for the selected [rangeDays] window (earliest first).
  /// Empty when a caller overrides the summary without providing it; fall back
  /// to [lastSevenDaysKg] when rendering.
  final List<double> dailyKg;

  /// Total kg avoided grouped by category name.
  final Map<String, double> categoryKg;
}

/// Reads the diary and groups by local day and category in Dart. The window is
/// small enough that loading it and grouping in memory beats timezone-aware
/// SQL date functions.
///
/// [rangeDays] selects the chart window; pass null for "all time" (buckets run
/// from the first logged day).
Future<ImpactSummary> computeImpactSummary(
  ActionLogRepository repository,
  DateTime now, {
  int? rangeDays = 7,
}) async {
  final today = dateOnly(now);
  final endExclusive = nextDay(today);
  final startOfTime = DateTime.fromMillisecondsSinceEpoch(0);

  final days = rangeDays ??
      await _spanDays(repository, startOfTime, endExclusive, today);

  final windowStart = today.subtract(Duration(days: days - 1));
  final windowLogs = await repository.between(windowStart, endExclusive);

  final daily = List<double>.filled(days, 0.0);
  for (final log in windowLogs) {
    final day = dateOnly(log.happenedOn);
    final index = day.difference(windowStart).inDays;
    if (index >= 0 && index < days) {
      daily[index] += log.kgCo2e;
    }
  }

  final totalKg = await repository.sumKgBetween(startOfTime, endExclusive);
  final totalActions = await repository.countBetween(startOfTime, endExclusive);
  final categoryKg =
      await repository.categorySumBetween(startOfTime, endExclusive);

  return ImpactSummary(
    totalKg: totalKg,
    totalActions: totalActions,
    lastSevenDaysKg: days >= 7 ? daily.sublist(days - 7) : List.of(daily),
    dailyKg: daily,
    categoryKg: categoryKg,
  );
}

/// Days from the first logged day through today, or a week when empty.
Future<int> _spanDays(
  ActionLogRepository repository,
  DateTime start,
  DateTime endExclusive,
  DateTime today,
) async {
  final earliest = await repository.earliestDateBetween(start, endExclusive);
  if (earliest == null) return 7;
  return today.difference(earliest).inDays + 1;
}
