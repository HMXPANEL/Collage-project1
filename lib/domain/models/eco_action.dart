import 'package:flutter/foundation.dart';

import 'emission_factor.dart';

enum ImpactType { perUnit, baselineAlternative }

ImpactType impactTypeFromName(String name) {
  for (final type in ImpactType.values) {
    if (type.name == name) return type;
  }
  throw FormatException('Unknown impact type: $name');
}

/// Describes how an action's CO2e estimate is computed:
///
///  * [ImpactType.perUnit] — estimate = quantity * factor value (factor must
///    be an `avoidance` factor).
///  * [ImpactType.baselineAlternative] — estimate = quantity * (baseline -
///    alternative), i.e. the CO2e *avoided* by choosing the alternative
///    instead of the baseline.
@immutable
class ActionImpactSpec {
  const ActionImpactSpec.perUnit({
    required this.factorId,
    required this.quantityUnit,
    this.quantityLabel,
  }) : type = ImpactType.perUnit,
       baselineFactorId = null,
       alternativeFactorId = null;

  const ActionImpactSpec.baselineAlternative({
    required this.baselineFactorId,
    required this.alternativeFactorId,
    required this.quantityUnit,
    this.quantityLabel,
  }) : type = ImpactType.baselineAlternative,
       factorId = null;

  final ImpactType type;
  final String? factorId;
  final String? baselineFactorId;
  final String? alternativeFactorId;
  final String quantityUnit;
  final String? quantityLabel;

  factory ActionImpactSpec.fromJson(Map<String, dynamic> json) {
    final type = impactTypeFromName(json['type'] as String);
    final unit = json['quantityUnit'] as String;
    final label = json['quantityLabel'] as String?;
    if (type == ImpactType.perUnit) {
      return ActionImpactSpec.perUnit(
        factorId: json['factorId'] as String,
        quantityUnit: unit,
        quantityLabel: label,
      );
    }
    return ActionImpactSpec.baselineAlternative(
      baselineFactorId: json['baselineFactorId'] as String,
      alternativeFactorId: json['alternativeFactorId'] as String,
      quantityUnit: unit,
      quantityLabel: label,
    );
  }
}

@immutable
class EcoAction {
  const EcoAction({
    required this.id,
    required this.title,
    required this.description,
    required this.whyItHelps,
    required this.category,
    required this.icon,
    required this.impact,
    this.seed = false,
  });

  final String id;
  final String title;
  final String description;
  final String whyItHelps;
  final EmissionCategory category;

  /// Semantic icon key, resolved to an IconData by the UI.
  final String icon;
  final ActionImpactSpec impact;

  /// True for development seed content; may be revisited later.
  final bool seed;

  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      whyItHelps: json['whyItHelps'] as String,
      category: emissionCategoryFromName(json['category'] as String),
      icon: json['icon'] as String,
      impact: ActionImpactSpec.fromJson(json['impact'] as Map<String, dynamic>),
      seed: json['seed'] as bool? ?? false,
    );
  }
}
