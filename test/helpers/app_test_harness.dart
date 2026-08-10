import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/profile_repository.dart';
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
