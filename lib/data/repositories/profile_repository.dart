import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final Database _db;

  static const String _table = 'profile';

  Future<UserProfile?> get() async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromRow(rows.first);
  }

  Future<void> save(UserProfile profile) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insert(
      _table,
      {
        'id': 1,
        'region': profile.region,
        'transport_baseline': profile.transportBaseline,
        'daily_commute_km': profile.dailyCommuteKm,
        'interests': jsonEncode(profile.interests),
        'habits': jsonEncode(profile.habits),
        'onboarded': profile.onboarded ? 1 : 0,
        'reminder_minutes': profile.reminderMinutesFromMidnight,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clear() async {
    await _db.delete(_table);
  }
}
