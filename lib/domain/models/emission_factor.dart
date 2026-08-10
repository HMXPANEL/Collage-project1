import 'package:flutter/foundation.dart';

enum EmissionCategory { transport, energy, waste, water, food, lifestyle }

extension EmissionCategoryX on EmissionCategory {
  String get label => switch (this) {
        EmissionCategory.transport => 'Transport',
        EmissionCategory.energy => 'Energy',
        EmissionCategory.waste => 'Waste',
        EmissionCategory.water => 'Water',
        EmissionCategory.food => 'Food',
        EmissionCategory.lifestyle => 'Lifestyle',
      };
}

EmissionCategory emissionCategoryFromName(String name) {
  for (final category in EmissionCategory.values) {
    if (category.name == name) return category;
  }
  throw FormatException('Unknown emission category: $name');
}

enum FactorStatus { provisional, verified }

/// Whether a factor describes kg CO2e *emitted* per unit, or kg CO2e
/// directly *avoided* per unit.
enum EmissionFactorKind { emission, avoidance }

@immutable
class EmissionFactor {
  const EmissionFactor({
    required this.id,
    required this.value,
    required this.unit,
    required this.category,
    required this.region,
    required this.version,
    required this.sourceName,
    required this.sourceReference,
    required this.notes,
    this.uncertainty = 'MEDIUM',
    this.uncertaintyPercent,
    this.status = FactorStatus.provisional,
    required this.kind,
  });

  final String id;

  /// kg CO2e per [unit] (emitted or avoided, see [kind]).
  final double value;
  final String unit;
  final EmissionCategory category;

  /// Region key the factor applies to (e.g. 'in', 'global').
  final String region;
  final String version;
  final String sourceName;
  final String sourceReference;
  final String notes;

  /// 'LOW' | 'MEDIUM' | 'HIGH'
  final String uncertainty;
  final double? uncertaintyPercent;
  final FactorStatus status;
  final EmissionFactorKind kind;

  bool get isProvisional => status == FactorStatus.provisional;

  bool get isHighUncertainty => uncertainty == 'HIGH';

  factory EmissionFactor.fromJson(Map<String, dynamic> json) {
    return EmissionFactor(
      id: json['id'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      category: emissionCategoryFromName(json['category'] as String),
      region: json['region'] as String,
      version: json['version'] as String,
      sourceName: json['sourceName'] as String,
      sourceReference: json['sourceReference'] as String,
      notes: json['notes'] as String,
      uncertainty: json['uncertainty'] as String,
      uncertaintyPercent: (json['uncertaintyPercent'] as num?)?.toDouble(),
      status: json['status'] == 'verified'
          ? FactorStatus.verified
          : FactorStatus.provisional,
      kind: json['kind'] == 'avoidance'
          ? EmissionFactorKind.avoidance
          : EmissionFactorKind.emission,
    );
  }
}
