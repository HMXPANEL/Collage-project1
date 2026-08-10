import 'package:sqflite/sqflite.dart';

import '../../core/dates.dart';
import '../../domain/models/action_log.dart';

/// Queries over the activity diary. Aggregations are done in SQL so the app
/// never loads the whole table into Dart memory.
class ActionLogRepository {
  ActionLogRepository(this._db);

  final Database _db;

  static const String _table = 'action_log';

  Future<int> add(ActionLog log) {
    return _db.insert(_table, log.toRow());
  }

  Future<int> deleteById(int id) {
    return _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Logs from [start] (inclusive) to [endExclusive).
  Future<List<ActionLog>> between(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final rows = await _db.query(
      _table,
      where: 'happened_on >= ? AND happened_on < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        endExclusive.millisecondsSinceEpoch,
      ],
      orderBy: 'happened_on DESC',
    );
    return rows.map(ActionLog.fromRow).toList();
  }

  Future<double> sumKgBetween(DateTime start, DateTime endExclusive) async {
    final rows = await _db.rawQuery(
      'SELECT SUM(kg_co2e) AS total FROM $_table '
      'WHERE happened_on >= ? AND happened_on < ?',
      [start.millisecondsSinceEpoch, endExclusive.millisecondsSinceEpoch],
    );
    final total = rows.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  Future<int> countBetween(DateTime start, DateTime endExclusive) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_table '
      'WHERE happened_on >= ? AND happened_on < ?',
      [start.millisecondsSinceEpoch, endExclusive.millisecondsSinceEpoch],
    );
    return (rows.first['total'] as num).toInt();
  }

  Future<Map<String, double>> categorySumBetween(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final rows = await _db.rawQuery(
      'SELECT category, SUM(kg_co2e) AS total FROM $_table '
      'WHERE happened_on >= ? AND happened_on < ? '
      'GROUP BY category',
      [start.millisecondsSinceEpoch, endExclusive.millisecondsSinceEpoch],
    );
    return {
      for (final row in rows)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  /// Distinct local days with at least one log, within [start, endExclusive).
  Future<Set<DateTime>> distinctDatesBetween(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT happened_on FROM $_table '
      'WHERE happened_on >= ? AND happened_on < ?',
      [start.millisecondsSinceEpoch, endExclusive.millisecondsSinceEpoch],
    );
    final result = <DateTime>{};
    for (final row in rows) {
      final day = dateOnly(
        DateTime.fromMillisecondsSinceEpoch(row['happened_on'] as int),
      );
      result.add(day);
    }
    return result;
  }

  /// Removes every log entry (used by data-management/wipe).
  Future<int> wipe() => _db.delete(_table);
}
