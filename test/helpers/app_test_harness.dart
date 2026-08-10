import 'package:eco_action/core/state/providers.dart';
import 'package:eco_action/data/db/app_database.dart';
import 'package:eco_action/data/repositories/profile_repository.dart';
import 'package:eco_action/domain/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
        region: 'in', transportBaseline: 'scooter', onboarded: true),
  );
}
