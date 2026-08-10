import 'package:flutter/foundation.dart';

enum ChallengeRuleType { countActions, countCategoryActions }

ChallengeRuleType challengeRuleTypeFromName(String name) {
  for (final type in ChallengeRuleType.values) {
    if (type.name == name) return type;
  }
  throw FormatException('Unknown challenge rule type: $name');
}

@immutable
class ChallengeRule {
  const ChallengeRule({
    required this.type,
    required this.target,
    required this.windowDays,
    this.category,
  });

  final ChallengeRuleType type;

  /// Number of qualifying log entries required.
  final int target;

  /// How many days the challenge runs.
  final int windowDays;

  /// Required category for [ChallengeRuleType.countCategoryActions].
  final String? category;

  factory ChallengeRule.fromJson(Map<String, dynamic> json) {
    final type = challengeRuleTypeFromName(json['type'] as String);
    final category =
        type == ChallengeRuleType.countCategoryActions
            ? json['category'] as String
            : null;
    return ChallengeRule(
      type: type,
      target: (json['target'] as num).toInt(),
      windowDays: (json['windowDays'] as num).toInt(),
      category: category,
    );
  }
}

@immutable
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rule,
  });

  final String id;
  final String title;
  final String description;

  /// Semantic icon key, resolved by the UI.
  final String icon;
  final ChallengeRule rule;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      rule: ChallengeRule.fromJson(json['rule'] as Map<String, dynamic>),
    );
  }
}

/// A user's contribution to a challenge on one local day.
@immutable
class ChallengeProgress {
  const ChallengeProgress({
    this.id,
    required this.challengeId,
    required this.dateDay,
    required this.amount,
  });

  final int? id;
  final String challengeId;
  final DateTime dateDay;
  final double amount;

  factory ChallengeProgress.fromRow(Map<String, Object?> row) {
    return ChallengeProgress(
      id: row['id'] as int?,
      challengeId: row['challenge_id'] as String,
      dateDay: DateTime.fromMillisecondsSinceEpoch(row['date_day'] as int),
      amount: (row['amount'] as num).toDouble(),
    );
  }
}