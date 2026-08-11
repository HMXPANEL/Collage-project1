import 'package:eco_action/domain/models/user_profile.dart';
import 'package:eco_action/features/coach/coach_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const emptyContext = CoachContext(
  profile: UserProfile(region: 'in'),
  categories: [],
  totalKg: 0,
  totalActions: 0,
  currentStreak: 0,
);

void main() {
  const coach = RulesCoach();

  test('greeting returns a message with suggestions', () {
    final reply = coach.reply('hello', emptyContext);
    expect(reply.message, contains('coach'));
    expect(reply.suggestions, isNotEmpty);
  });

  test('streak query reflects the live streak', () {
    const context = CoachContext(
      profile: UserProfile(region: 'in'),
      categories: [],
      totalKg: 1,
      totalActions: 1,
      currentStreak: 4,
    );
    final reply = coach.reply('how is my streak?', context);
    expect(reply.message, contains('4-day'));
  });

  test('zero-streak query nudges to start one', () {
    final reply = coach.reply('keep me motivated', emptyContext);
    expect(reply.message, contains('Start one today'));
  });

  test('first-time user gets starter ideas', () {
    final reply = coach.reply('suggest something new', emptyContext);
    expect(reply.suggestions.length, 3);
  });

  test('impact query reports total kg', () {
    const gained = CoachContext(
      profile: UserProfile(region: 'in'),
      categories: [],
      totalKg: 12.5,
      totalActions: 3,
      currentStreak: 0,
    );
    final reply = coach.reply('show my impact kg', gained);
    expect(reply.message, contains('12'));
  });
}
