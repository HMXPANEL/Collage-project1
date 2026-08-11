import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/action_log_repository.dart';
import 'package:eco_action/data/repositories/profile_repository.dart';
import 'package:eco_action/domain/models/action_log.dart';
import 'package:eco_action/domain/models/eco_action.dart';
import 'package:eco_action/domain/models/emission_factor.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// In-memory repository used by widget tests so the UI never touches the
/// native SQLite plugin inside testWidgets' fake-async zone.
class MemoryProfileRepository implements ProfileRepository {
  MemoryProfileRepository({this.profile});

  UserProfile? profile;

  @override
  Future<UserProfile?> get() async => profile;

  @override
  Future<void> save(UserProfile value) async {
    profile = value;
  }

  @override
  Future<void> clear() async {
    profile = null;
  }
}

/// Override that seeds [profileProvider] from an in-memory repository.
List<Override> profileOverrides(MemoryProfileRepository repository) => [
      profileProvider.overrideWith(
        () => ProfileController(repository: repository),
      ),
    ];

/// In-memory diary so widget tests never touch the SQLite plugin.
class MemoryActionLogRepository implements ActionLogRepository {
  final List<ActionLog> logs = [];
  int _nextId = 1;

  @override
  Future<int> add(ActionLog log) async {
    logs.add(
      ActionLog(
        id: _nextId++,
        actionId: log.actionId,
        actionTitle: log.actionTitle,
        category: log.category,
        happenedOn: log.happenedOn,
        kgCo2e: log.kgCo2e,
        quantity: log.quantity,
        inputUnit: log.inputUnit,
        provisional: log.provisional,
        createdAt: log.createdAt,
      ),
    );
    return logs.last.id!;
  }

  @override
  Future<List<ActionLog>> between(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final result = <ActionLog>[];
    for (final l in logs) {
      if (l.happenedOn.isBefore(start)) continue;
      if (!l.happenedOn.isBefore(endExclusive)) continue;
      result.add(l);
    }
    result.sort((a, b) => b.happenedOn.compareTo(a.happenedOn));
    return result;
  }

  @override
  Future<double> sumKgBetween(DateTime start, DateTime endExclusive) async {
    var total = 0.0;
    for (final l in await between(start, endExclusive)) {
      total += l.kgCo2e;
    }
    return total;
  }

  @override
  Future<int> countBetween(DateTime start, DateTime endExclusive) async {
    return (await between(start, endExclusive)).length;
  }

  @override
  Future<Map<String, double>> categorySumBetween(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final map = <String, double>{};
    for (final l in await between(start, endExclusive)) {
      map[l.category] = (map[l.category] ?? 0) + l.kgCo2e;
    }
    return map;
  }

  @override
  Future<Set<DateTime>> distinctDatesBetween(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final days = <DateTime>{};
    for (final l in await between(start, endExclusive)) {
      final day =
          DateTime(l.happenedOn.year, l.happenedOn.month, l.happenedOn.day);
      days.add(day);
    }
    return days;
  }

  @override
  Future<int> deleteById(int id) async {
    final before = logs.length;
    logs.removeWhere((l) => l.id == id);
    return before - logs.length;
  }

  @override
  Future<int> wipe() async {
    final count = logs.length;
    logs.clear();
    return count;
  }
}

/// Overrides the catalog and diary with in-memory data for widget tests.
List<Override> catalogOverrides({
  required List<EcoAction> actions,
  required Map<String, EmissionFactor> factors,
  MemoryActionLogRepository? actionLogs,
}) =>
    [
      actionsProvider.overrideWith((ref) async => actions),
      emissionFactorsProvider.overrideWith((ref) async => factors),
      if (actionLogs != null)
        actionLogRepositoryProvider.overrideWith((ref) async => actionLogs),
    ];

Future<Database> openTestDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: AppDatabaseSchema.version,
      onCreate: AppDatabaseSchema.create,
    ),
  );
}

List<Override> appOverrides(Database db) => [
      databaseProvider.overrideWith((ref) async => db),
    ];

Future<void> seedOnboardedProfile(Database db) {
  return ProfileRepository(db).save(
    const UserProfile(
      region: 'in',
      transportBaseline: 'scooter',
      onboarded: true,
    ),
  );
}
