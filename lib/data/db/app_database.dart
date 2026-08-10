import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';

/// SQL schema for the local-first database.
///
/// Stores the user's activity "diary"; the catalog (actions/factors/badges/
/// challenges) lives in read-only assets instead.
abstract final class AppDatabaseSchema {
  static const int version = AppConstants.dbSchemaVersion;

  static Future<void> create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        region TEXT NOT NULL DEFAULT 'in',
        transport_baseline TEXT,
        daily_commute_km REAL,
        interests TEXT NOT NULL DEFAULT '[]',
        habits TEXT NOT NULL DEFAULT '{}',
        onboarded INTEGER NOT NULL DEFAULT 0,
        reminder_minutes INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE action_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_id TEXT NOT NULL,
        action_title TEXT NOT NULL,
        category TEXT NOT NULL,
        happened_on INTEGER NOT NULL,
        quantity REAL,
        input_unit TEXT,
        kg_co2e REAL NOT NULL,
        provisional INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_action_log_happened ON action_log(happened_on)',
    );
    await db.execute(
      'CREATE INDEX idx_action_log_category ON action_log(category)',
    );

    await db.execute('''
      CREATE TABLE challenge_progress(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_id TEXT NOT NULL,
        date_day INTEGER NOT NULL,
        amount REAL NOT NULL,
        UNIQUE(challenge_id, date_day)
      )
    ''');

    await db.execute('''
      CREATE TABLE badges_earned(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        badge_id TEXT NOT NULL UNIQUE,
        earned_on INTEGER NOT NULL
      )
    ''');
  }
}

class AppDatabase {
  AppDatabase._();

  static Future<Database> open({String? path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    String dbPath;
    if (path != null) {
      dbPath = path;
    } else {
      final base = await f.getDatabasesPath();
      final normalized = base.replaceFirst(RegExp(r'/+$'), '');
      dbPath = '$normalized/${AppConstants.dbFileName}';
    }
    return f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppDatabaseSchema.version,
        onCreate: AppDatabaseSchema.create,
      ),
    );
  }
}
