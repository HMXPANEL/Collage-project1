import 'dart:convert';

import '../../data/repositories/action_log_repository.dart';
import '../../data/repositories/badge_repository.dart';
import '../../data/repositories/challenge_progress_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/action_log.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/user_profile.dart';

/// One export payload: everything the app stores about the user, as JSON.
class BackupPayload {
  const BackupPayload({
    required this.version,
    required this.exportedAt,
    required this.profile,
    required this.logs,
    required this.badges,
    required this.challengeProgress,
  });

  final int version;
  final String exportedAt;
  final UserProfile? profile;
  final List<ActionLog> logs;
  final List<String> badges;
  final List<ChallengeProgress> challengeProgress;

  Map<String, Object?> toJson() => {
        'version': version,
        'exportedAt': exportedAt,
        'profile': profile?.toRow(),
        'logs': [for (final log in logs) log.toRow()],
        'badges': badges,
        'challengeProgress': [
          for (final p in challengeProgress) p.toRow(),
        ],
      };

  static BackupPayload fromJson(Map<String, Object?> json) {
    const decoder = _RowDecoder();
    return BackupPayload(
      version: (json['version'] as num?)?.toInt() ?? 0,
      exportedAt: json['exportedAt'] as String? ?? '',
      profile: json['profile'] == null
          ? null
          : UserProfile.fromRow(
              (json['profile'] as Map).cast<String, Object?>()),
      logs:
          ((json['logs'] as List?) ?? const []).map(decoder.actionLog).toList(),
      badges: ((json['badges'] as List?) ?? const []).cast<String>(),
      challengeProgress: ((json['challengeProgress'] as List?) ?? const [])
          .map(decoder.challengeProgress)
          .toList(),
    );
  }
}

/// Reads the whole app database into a [BackupPayload] and restores one.
/// Pure Dart (except the repositories it is handed), so it is testable with
/// the ffi database.
class DataPortService {
  DataPortService({
    required ProfileRepository profile,
    required ActionLogRepository actionLogs,
    required BadgeRepository badges,
    required ChallengeProgressRepository challengeProgress,
  })  : _profile = profile,
        _actionLogs = actionLogs,
        _badges = badges,
        _challengeProgress = challengeProgress;

  static const int currentVersion = 1;

  final ProfileRepository _profile;
  final ActionLogRepository _actionLogs;
  final BadgeRepository _badges;
  final ChallengeProgressRepository _challengeProgress;

  Future<BackupPayload> exportAll() async {
    // Serialize the whole diary using a far-future end bound.
    final end = DateTime(9999);
    return BackupPayload(
      version: currentVersion,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      profile: await _profile.get(),
      logs: await _actionLogs.between(
        DateTime.fromMillisecondsSinceEpoch(0),
        end,
      ),
      badges: await _badges.earned(),
      challengeProgress: await _challengeProgress.all(),
    );
  }

  /// Restores a payload. Overwrites existing local data after validation.
  Future<void> import(BackupPayload payload) async {
    final problems = validate(payload);
    if (problems.isNotEmpty) {
      throw const FormatException('Invalid backup');
    }
    if (payload.profile != null) {
      await _profile.save(payload.profile!);
    }
    await _actionLogs.wipe();
    for (final log in payload.logs) {
      await _actionLogs.add(log);
    }
    await _badges.wipe();
    for (final badge in payload.badges) {
      await _badges.award(badge);
    }
    await _challengeProgress.wipe();
    for (final progress in payload.challengeProgress) {
      await _challengeProgress.setAmount(
        progress.challengeId,
        progress.dateDay,
        progress.amount,
      );
    }
  }

  /// Removes every table's data. Used by Settings → Delete all data.
  Future<void> wipeAll() async {
    await _profile.clear();
    await _actionLogs.wipe();
    await _badges.wipe();
    await _challengeProgress.wipe();
  }

  static String encode(BackupPayload payload) =>
      const JsonEncoder.withIndent('  ').convert(payload.toJson());

  static Map<String, Object?> decode(String json) =>
      (jsonDecode(json) as Map).cast<String, Object?>();

  /// Rules a payload must satisfy before it can be imported. Empty = valid.
  List<String> validate(BackupPayload payload) {
    final problems = <String>[];
    if (payload.version != currentVersion) {
      problems.add('Expected payload version $currentVersion, got '
          '${payload.version}.');
    }
    for (final log in payload.logs) {
      if (log.actionId.isEmpty) problems.add('Log row missing action_id.');
    }
    return problems;
  }
}

class _RowDecoder {
  const _RowDecoder();

  ActionLog actionLog(Object? e) =>
      ActionLog.fromRow((e as Map).cast<String, Object?>());

  ChallengeProgress challengeProgress(Object? e) =>
      ChallengeProgress.fromRow((e as Map).cast<String, Object?>());
}
