import 'package:eco_action/domain/engines/streak_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = const StreakEngine();
  final today = DateTime(2026, 8, 10);

  DateTime day(int back) => DateTime(2026, 8, 10 - back);

  test('no activity means zero streak', () {
    expect(engine.currentStreak(const {}, today), 0);
    expect(engine.bestStreak(const {}), 0);
  });

  test('activity only today counts as one', () {
    expect(engine.currentStreak({day(0)}, today), 1);
  });

  test('activity only yesterday keeps the streak alive', () {
    expect(engine.currentStreak({day(1)}, today), 1);
  });

  test('consecutive days ending today count back', () {
    final days = {day(0), day(1), day(2), day(3)};
    expect(engine.currentStreak(days, today), 4);
  });

  test('a gap ends the current streak', () {
    final days = {day(0), day(2)};
    expect(engine.currentStreak(days, today), 1);
  });

  test('stale streaks (no today or yesterday activity) are zero', () {
    final days = {day(2), day(3), day(4)};
    expect(engine.currentStreak(days, today), 0);
  });

  test('bestStreak finds the longest historical run', () {
    final days = {
      day(0),
      day(1),
      day(2),
      day(4),
      day(5),
      day(6),
      day(7),
    };
    expect(engine.bestStreak(days), 4);
  });
}
