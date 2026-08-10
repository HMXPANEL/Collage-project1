import 'package:sqflite/sqflite.dart';

class BadgeRepository {
  BadgeRepository(this._db);

  final Database _db;

  static const String _table = 'badges_earned';

  Future<void> award(String badgeId) async {
    await _db.insert(_table, {
      'badge_id': badgeId,
      'earned_on': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<bool> has(String badgeId) async {
    final rows = await _db.query(
      _table,
      where: 'badge_id = ?',
      whereArgs: [badgeId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<String>> earned() async {
    final rows = await _db.query(_table, orderBy: 'earned_on ASC');
    return [for (final row in rows) row['badge_id'] as String];
  }
}
