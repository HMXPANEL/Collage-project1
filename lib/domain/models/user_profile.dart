import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Personalization data collected during onboarding and settings.
///
/// [interests] holds EmissionCategory names; [habits] holds free-form
/// onboarding answers keyed by question id. Nothing beyond this is collected.
@immutable
class UserProfile {
  const UserProfile({
    required this.region,
    this.transportBaseline,
    this.dailyCommuteKm,
    this.interests = const [],
    this.habits = const {},
    this.onboarded = false,
    this.reminderMinutesFromMidnight,
  });

  final String region;

  /// Typical transport mode: 'car', 'scooter', 'bus', 'cycle', 'walk', 'none'.
  final String? transportBaseline;
  final double? dailyCommuteKm;
  final List<String> interests;
  final Map<String, String> habits;
  final bool onboarded;
  final int? reminderMinutesFromMidnight;

  factory UserProfile.fromRow(Map<String, Object?> row) {
    final interests =
        (jsonDecode(row['interests'] as String) as List).cast<String>();
    final habits = (jsonDecode(row['habits'] as String) as Map<String, dynamic>)
        .cast<String, String>();
    return UserProfile(
      region: row['region'] as String,
      transportBaseline: row['transport_baseline'] as String?,
      dailyCommuteKm: (row['daily_commute_km'] as num?)?.toDouble(),
      interests: interests,
      habits: habits,
      onboarded: (row['onboarded'] as int) == 1,
      reminderMinutesFromMidnight: row['reminder_minutes'] as int?,
    );
  }

  /// Row form used by persistence and backup export.
  Map<String, Object?> toRow() => {
        'id': 1,
        'region': region,
        'transport_baseline': transportBaseline,
        'daily_commute_km': dailyCommuteKm,
        'interests': jsonEncode(interests),
        'habits': jsonEncode(habits),
        'onboarded': onboarded ? 1 : 0,
        'reminder_minutes': reminderMinutesFromMidnight,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
}
