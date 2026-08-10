import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../domain/models/badge.dart';
import '../../domain/models/challenge.dart';
import '../../domain/models/eco_action.dart';
import '../../domain/models/emission_factor.dart';

/// Loads and caches the read-only content catalog from assets.
///
/// Loading happens once and the result is cached in memory; the catalog does
/// not change during a session.
class CatalogRepository {
  CatalogRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<List<EcoAction>>? _actions;
  Future<Map<String, EmissionFactor>>? _factors;
  Future<List<Badge>>? _badges;
  Future<List<Challenge>>? _challenges;

  Future<List<EcoAction>> actions() => _actions ??= _loadActions();

  /// Factors indexed by id. Region selection happens at estimation time.
  Future<Map<String, EmissionFactor>> factors() => _factors ??= _loadFactors();

  Future<List<Badge>> badges() => _badges ??= _loadBadges();

  Future<List<Challenge>> challenges() => _challenges ??= _loadChallenges();

  Future<List<EcoAction>> _loadActions() async {
    final data = await _bundle.loadString(AppConstants.actionsAsset);
    final list = (jsonDecode(data) as Map<String, dynamic>)['actions'] as List;
    final result = <EcoAction>[];
    for (final e in list) {
      result.add(EcoAction.fromJson(e as Map<String, dynamic>));
    }
    return result;
  }

  Future<Map<String, EmissionFactor>> _loadFactors() async {
    final data = await _bundle.loadString(AppConstants.factorsAsset);
    final list = (jsonDecode(data) as Map<String, dynamic>)['factors'] as List;
    final result = <String, EmissionFactor>{};
    for (final e in list) {
      final map = e as Map<String, dynamic>;
      result[map['id'] as String] = EmissionFactor.fromJson(map);
    }
    return result;
  }

  Future<List<Badge>> _loadBadges() async {
    final data = await _bundle.loadString(AppConstants.badgesAsset);
    final list = (jsonDecode(data) as Map<String, dynamic>)['badges'] as List;
    final result = <Badge>[];
    for (final e in list) {
      result.add(Badge.fromJson(e as Map<String, dynamic>));
    }
    return result;
  }

  Future<List<Challenge>> _loadChallenges() async {
    final data = await _bundle.loadString(AppConstants.challengesAsset);
    final list =
        (jsonDecode(data) as Map<String, dynamic>)['challenges'] as List;
    final result = <Challenge>[];
    for (final e in list) {
      result.add(Challenge.fromJson(e as Map<String, dynamic>));
    }
    return result;
  }

  /// Integrity checks over the whole catalog. The test suite asserts that the
  /// result is empty; CI fails fast on bad content instead of shipping it.
  Future<List<String>> validate() async {
    final issues = <String>[];
    final factorMap = await factors();
    final actionList = await actions();
    final badgeList = await badges();
    final challengeList = await challenges();

    final factorIds = factorMap.keys.toSet();
    _checkUnique('factor', factorIds, issues);

    for (final factor in factorMap.values) {
      if (factor.value < 0) {
        issues.add('factor ${factor.id}: value must not be negative');
      }
      if (factor.sourceName.isEmpty || factor.sourceReference.isEmpty) {
        issues.add('factor ${factor.id}: missing sourceName/sourceReference');
      }
      if (factor.notes.isEmpty) {
        issues.add('factor ${factor.id}: missing notes');
      }
      if (factor.version.isEmpty) {
        issues.add('factor ${factor.id}: missing version');
      }
      if (factor.region.isEmpty) {
        issues.add('factor ${factor.id}: missing region');
      }
      if (factor.uncertainty != 'LOW' &&
          factor.uncertainty != 'MEDIUM' &&
          factor.uncertainty != 'HIGH') {
        issues.add('factor ${factor.id}: uncertainty must be LOW/MEDIUM/HIGH');
      }
    }

    _checkUnique('action', actionList.map((a) => a.id), issues);
    for (final action in actionList) {
      if (action.title.isEmpty ||
          action.description.isEmpty ||
          action.whyItHelps.isEmpty) {
        issues.add('action ${action.id}: missing title/description/whyItHelps');
      }
      if (action.impact.quantityUnit.isEmpty) {
        issues.add('action ${action.id}: missing quantityUnit');
      }
      switch (action.impact.type) {
        case ImpactType.perUnit:
          if (!factorIds.contains(action.impact.factorId)) {
            issues.add(
              'action ${action.id}: unknown perUnit factor '
              '${action.impact.factorId}',
            );
          }
          break;
        case ImpactType.baselineAlternative:
          if (!factorIds.contains(action.impact.baselineFactorId)) {
            issues.add(
              'action ${action.id}: unknown baseline factor '
              '${action.impact.baselineFactorId}',
            );
          }
          if (!factorIds.contains(action.impact.alternativeFactorId)) {
            issues.add(
              'action ${action.id}: unknown alternative factor '
              '${action.impact.alternativeFactorId}',
            );
          }
          break;
      }
    }

    _checkUnique('badge', badgeList.map((b) => b.id), issues);
    for (final badge in badgeList) {
      if (badge.condition.value < 1) {
        issues.add('badge ${badge.id}: condition value must be >= 1');
      }
    }

    _checkUnique('challenge', challengeList.map((c) => c.id), issues);
    for (final challenge in challengeList) {
      if (challenge.rule.target < 1 || challenge.rule.windowDays < 1) {
        issues.add('challenge ${challenge.id}: target and windowDays >= 1');
      }
      final category = challenge.rule.category;
      if (category != null) {
        try {
          emissionCategoryFromName(category);
        } on FormatException {
          issues.add('challenge ${challenge.id}: invalid category $category');
        }
      }
    }

    return issues;
  }

  void _checkUnique(String kind, Iterable<String> ids, List<String> issues) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) {
        issues.add('$kind: duplicate id "$id"');
      }
    }
  }
}
