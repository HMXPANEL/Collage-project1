/// Deterministic rule-based climate coach.
///
/// [RulesCoach] answers offline with patterns matched against a user's
/// context — no network, no model. Every response is grounded in the user's
/// actual profile, streak and diary so the "coach" never makes things up.
library;

import '../../domain/models/eco_action.dart';
import '../../domain/models/user_profile.dart';

/// What the coach knows about the user at reply time.
class CoachContext {
  const CoachContext({
    required this.profile,
    required this.categories,
    required this.totalKg,
    required this.totalActions,
    required this.currentStreak,
    required this.habits = const {},
    this.preferredActions = const [],
  });

  final UserProfile profile;
  final List<String> categories;
  final double totalKg;
  final int totalActions;
  final int currentStreak;
  final Map<String, String> habits;

  /// EcoAction ids the user has already logged, used to suggest "new" ideas.
  final List<String> preferredActions;
}

/// A single coach reply: a short message plus up to three follow-up chips.
class CoachReply {
  const CoachReply({required this.message, this.suggestions = const []});

  final String message;
  final List<String> suggestions;
}

/// Coach that cannot be plugged into a model yet. Implementations must be
/// pure so they are unit-testable offline.
abstract class CoachService {
  CoachReply reply(String prompt, CoachContext context);
}

class RulesCoach implements CoachService {
  const RulesCoach();

  static const _firstActions = [
    'Use a reusable water bottle',
    'Switch off lights when leaving a room',
    'Say no to plastic straws',
  ];

  static const _suggestions = [
    'Fix a reminder for my daily action',
    'Pick a challenge from the Challenges tab',
    'Review my biggest impact in Insights',
  ];

  @override
  CoachReply reply(String prompt, CoachContext context) {
    final q = prompt.toLowerCase().trim();

    if (q.contains('streak') ||
        q.contains('consistent') ||
        q.contains('motivat')) {
      return _onMotivation(context);
    }
    if (q.contains('new') ||
        q.contains('idea') ||
        q.contains('suggest') ||
        q.contains('what should i do')) {
      return _onSuggestion(context);
    }
    if (q.contains('impact') ||
        q.contains('kg') ||
        q.contains('co2') ||
        q.contains('carbon')) {
      return _onImpact(context);
    }
    if (q.contains('welcome') ||
        q.contains('hi') ||
        q.contains('hello') ||
        q.contains('help')) {
      return const CoachReply(
        message: 'Hi! I am your offline climate coach. Ask me about your '
            'streak, new action ideas, or how your impact adds up.',
        suggestions: _suggestions,
      );
    }

    return const CoachReply(
      message: 'I can help with your streak, new action ideas, and your '
          'running CO₂e impact. Try one of these:',
      suggestions: _suggestions,
    );
  }

  CoachReply _onMotivation(CoachContext context) {
    if (context.currentStreak > 0) {
      return CoachReply(
        message: 'You are on a ${context.currentStreak}-day streak. Keep the '
            'chain alive — one small action today is enough.',
        suggestions: const ['Log today’s action now', 'Review my impact'],
      );
    }
    return const CoachReply(
      message: 'No active streak yet. Start one today: log a single action '
          'and come back tomorrow. Small beats none.',
      suggestions: const ['Give me a new idea', 'Show my impact'],
    );
  }

  CoachReply _onSuggestion(CoachContext context) {
    if (context.totalActions == 0) {
      return const CoachReply(
        message: 'Here is where most people start:',
        suggestions: _firstActions,
      );
    }
    final done = context.preferredActions.toSet();
    final newIdeas = _firstActions.where((a) => !done.contains(a)).toList();
    if (newIdeas.isEmpty) {
      return const CoachReply(
        message: 'Nice — you have tried my starter ideas. Try a weekly '
            'challenge or revisit a category you log less often.',
        suggestions: _suggestions,
      );
    }
    return CoachReply(
      message: 'You have logged ${context.totalActions} actions. New idea:',
      suggestions: newIdeas,
    );
  }

  CoachReply _onImpact(CoachContext context) {
    if (context.totalKg <= 0) {
      return const CoachReply(
        message: 'No impact yet — log a first action and I will show how it '
            'adds up.',
        suggestions: _firstActions,
      );
    }
    return CoachReply(
      message: 'You have avoided ${context.totalKg.toStringAsFixed(0)} kg '
          'CO₂e across ${context.totalActions} actions. Keep going!',
      suggestions: const ['Review my impact', 'Suggest something new'],
    );
  }
}
