import 'package:flutter/foundation.dart';

import '../models/eco_action.dart';
import '../models/emission_factor.dart';

/// Result of estimating one action, the factors that were used, and flags that
/// tell the UI how honestly the number should be presented.
@immutable
class ImpactEstimate {
  const ImpactEstimate({
    required this.kgCo2e,
    required this.quantity,
    required this.quantityUnit,
    required this.usedFactors,
  });

  final double kgCo2e;
  final double quantity;
  final String quantityUnit;
  final List<EmissionFactor> usedFactors;

  bool get isProvisional => usedFactors.any((f) => f.isProvisional);

  bool get isHighUncertainty => usedFactors.any((f) => f.isHighUncertainty);

  /// Worst uncertainty among the factors used.
  String get uncertainty {
    const ranking = {'LOW': 0, 'MEDIUM': 1, 'HIGH': 2};
    var worst = 'LOW';
    for (final factor in usedFactors) {
      if (ranking[factor.uncertainty]! > ranking[worst]!) {
        worst = factor.uncertainty;
      }
    }
    return worst;
  }
}

/// Pure, deterministic CO2e estimation. No scientific values live here - the
/// engine is only a function over the factor table, so it is trivially
/// testable and the factors stay verifiable data.
class ImpactEngine {
  const ImpactEngine();

  /// Estimates kg CO2e for an action. [quantity] defaults to 1.
  ///
  /// The result is clamped to >= 0 (an alternative that pollutes more than the
  /// baseline never yields "negative avoidance").
  ImpactEstimate estimate({
    required ActionImpactSpec spec,
    required Map<String, EmissionFactor> factors,
    double? quantity,
  }) {
    final q = quantity ?? 1.0;
    if (q < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must not be negative');
    }

    double kg;
    final used = <EmissionFactor>[];
    switch (spec.type) {
      case ImpactType.perUnit:
        final factor = _requireFactor(factors, spec.factorId);
        used.add(factor);
        kg = q * factor.value;
        break;
      case ImpactType.baselineAlternative:
        final baseline = _requireFactor(factors, spec.baselineFactorId);
        final alternative = _requireFactor(factors, spec.alternativeFactorId);
        used.add(baseline);
        used.add(alternative);
        kg = q * (baseline.value - alternative.value);
        break;
    }

    if (kg < 0) kg = 0;
    kg = double.parse(kg.toStringAsFixed(4));

    return ImpactEstimate(
      kgCo2e: kg,
      quantity: q,
      quantityUnit: spec.quantityUnit,
      usedFactors: used,
    );
  }

  EmissionFactor _requireFactor(
    Map<String, EmissionFactor> factors,
    String? id,
  ) {
    final factor = factors[id];
    if (factor == null) {
      throw ArgumentError('Unknown factor id: $id');
    }
    return factor;
  }
}
