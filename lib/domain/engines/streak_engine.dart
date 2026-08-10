import 'package:flutter/foundation.dart';

/// Pure streak logic over a set of local days with activity.
///
/// A streak means at least one logged action on consecutive calendar days. The
/// current streak is "alive" if today has activity, or if only yesterday does
/// (today is still pending).
@immutable
class StreakEngine {
  const StreakEngine();

  List<DateTime> _sorted(Set<DateTime> days) {
    final list = <DateTime>[];
    for (final d in days) {
      list.add(DateTime(d.year, d.month, d.day));
    }
    list.sort();
    return list;
  }

  int currentStreak(Set<DateTime> activityDays, DateTime today) {
    if (activityDays.isEmpty) return 0;
    final set = _sorted(activityDays).toSet();
    final todayDay = DateTime(today.year, today.month, today.day);
    final yesterday = DateTime(todayDay.year, todayDay.month, todayDay.day - 1);

    if (!set.contains(todayDay) && !set.contains(yesterday)) return 0;
    var cursor = set.contains(todayDay) ? todayDay : yesterday;
    var count = 0;
    while (set.contains(cursor)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  int bestStreak(Set<DateTime> activityDays) {
    final sorted = _sorted(activityDays);
    if (sorted.isEmpty) return 0;
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      run = diff == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return best;
  }
}
