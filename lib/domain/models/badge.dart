import 'package:flutter/foundation.dart';

enum BadgeConditionType { countTotal, bestStreak, challengeCompleted }

BadgeConditionType badgeConditionTypeFromName(String name) {
  for (final type in BadgeConditionType.values) {
    if (type.name == name) return type;
  }
  throw FormatException('Unknown badge condition type: $name');
}

@immutable
class BadgeCondition {
  const BadgeCondition({required this.type, required this.value});

  final BadgeConditionType type;
  final int value;

  factory BadgeCondition.fromJson(Map<String, dynamic> json) {
    return BadgeCondition(
      type: badgeConditionTypeFromName(json['type'] as String),
      value: (json['value'] as num).toInt(),
    );
  }
}

@immutable
class Badge {
  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.condition,
  });

  final String id;
  final String title;
  final String description;

  /// Semantic icon key, resolved by the UI.
  final String icon;
  final BadgeCondition condition;

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      condition: BadgeCondition.fromJson(
        json['condition'] as Map<String, dynamic>,
      ),
    );
  }
}
