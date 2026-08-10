import 'package:sqflite/sqflite.dart';

import '../../core/dates.dart';
import '../../domain/models/challenge.dart';

class ChallengeProgressRepository {
  ChallengeProgressRepository(this._db);

  final Database _db;

  static const String _table = 'challenge_progress';

  Future<void> setAmount(
    String challengeId,
    DateTime dateDay,
    double amount,
  ) async {
    await _db.insert(
      _table,
      {
        'challenge_id': challengeId,
        'date_day': dateOnly(dateDay).millisecondsSinceEpoch,
        'amount': amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> total(String challengeId) async {
    final rows = await _db.rawQuery(
      'SELECT SUM(amount) AS total FROM $_table WHERE challenge_id = ?',
      [challengeId],
    );
    final total = rows.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  Future<List<ChallengeProgress>> forChallenge(String challengeId) async {
    final rows = await _db.query(
      _table,
      where: 'challenge_id = ?',
      whereArgs: [challengeId],
      orderBy: 'date_day ASC',
    );
    return rows.map(ChallengeProgress.fromRow).toList();
  }

  Future<int> wipe() => _db.delete(_table);
}
