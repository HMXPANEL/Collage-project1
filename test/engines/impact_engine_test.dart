import 'package:eco_action/domain/engines/impact_engine.dart';
import 'package:eco_action/domain/models/eco_action.dart';
import 'package:eco_action/domain/models/emission_factor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = const ImpactEngine();

  final car = EmissionFactor(
    id: 'car',
    value: 0.17,
    unit: 'km',
    category: EmissionCategory.transport,
    region: 'global',
    version: 't',
    sourceName: 's',
    sourceReference: 'r',
    notes: 'n',
    uncertainty: 'MEDIUM',
    status: FactorStatus.provisional,
    kind: EmissionFactorKind.emission,
  );
  final walking = EmissionFactor(
    id: 'walking',
    value: 0,
    unit: 'km',
    category: EmissionCategory.transport,
    region: 'global',
    version: 't',
    sourceName: 's',
    sourceReference: 'r',
    notes: 'n',
    uncertainty: 'LOW',
    status: FactorStatus.provisional,
    kind: EmissionFactorKind.avoidance,
  );
  final bottle = EmissionFactor(
    id: 'bottle',
    value: 0.05,
    unit: 'use',
    category: EmissionCategory.waste,
    region: 'global',
    version: 't',
    sourceName: 's',
    sourceReference: 'r',
    notes: 'n',
    uncertainty: 'HIGH',
    uncertaintyPercent: 50,
    status: FactorStatus.provisional,
    kind: EmissionFactorKind.avoidance,
  );

  final factors = {car.id: car, walking.id: walking, bottle.id: bottle};

  test('baselineAlternative multiplies the difference by quantity', () {
    final spec = const ActionImpactSpec.baselineAlternative(
      baselineFactorId: 'car',
      alternativeFactorId: 'walking',
      quantityUnit: 'km',
    );
    final estimate = engine.estimate(spec: spec, factors: factors, quantity: 5);
    expect(estimate.kgCo2e, closeTo(0.85, 0.0001));
    expect(estimate.quantity, 5);
  });

  test('perUnit multiplies the avoidance factor by quantity', () {
    final spec = const ActionImpactSpec.perUnit(
      factorId: 'bottle',
      quantityUnit: 'use',
    );
    final estimate = engine.estimate(spec: spec, factors: factors, quantity: 3);
    expect(estimate.kgCo2e, closeTo(0.15, 0.0001));
  });

  test('null quantity defaults to one', () {
    final spec = const ActionImpactSpec.perUnit(
      factorId: 'bottle',
      quantityUnit: 'use',
    );
    final estimate = engine.estimate(spec: spec, factors: factors);
    expect(estimate.kgCo2e, closeTo(0.05, 0.0001));
  });

  test('negative avoided emissions clamp to zero', () {
    final dirty = EmissionFactor(
      id: 'dirty',
      value: 0.5,
      unit: 'km',
      category: EmissionCategory.transport,
      region: 'global',
      version: 't',
      sourceName: 's',
      sourceReference: 'r',
      notes: 'n',
      uncertainty: 'MEDIUM',
      kind: EmissionFactorKind.emission,
    );
    final spec = const ActionImpactSpec.baselineAlternative(
      baselineFactorId: 'walking',
      alternativeFactorId: 'dirty',
      quantityUnit: 'km',
    );
    final estimate = engine.estimate(
      spec: spec,
      factors: {...factors, dirty.id: dirty},
      quantity: 10,
    );
    expect(estimate.kgCo2e, 0);
  });

  test('missing factor throws ArgumentError', () {
    final spec = const ActionImpactSpec.perUnit(
      factorId: 'does_not_exist',
      quantityUnit: 'use',
    );
    expect(
      () => engine.estimate(spec: spec, factors: factors),
      throwsArgumentError,
    );
  });

  test('negative quantity throws ArgumentError', () {
    final spec = const ActionImpactSpec.perUnit(
      factorId: 'bottle',
      quantityUnit: 'use',
    );
    expect(
      () => engine.estimate(spec: spec, factors: factors, quantity: -1),
      throwsArgumentError,
    );
  });

  test('provisional and uncertainty flags are propagated', () {
    final verifiedLow = EmissionFactor(
      id: 'verified_low',
      value: 0.01,
      unit: 'use',
      category: EmissionCategory.waste,
      region: 'global',
      version: 't',
      sourceName: 's',
      sourceReference: 'r',
      notes: 'n',
      uncertainty: 'LOW',
      status: FactorStatus.verified,
      kind: EmissionFactorKind.avoidance,
    );
    final spec = const ActionImpactSpec.perUnit(
      factorId: 'verified_low',
      quantityUnit: 'use',
    );
    final clean =
        engine.estimate(spec: spec, factors: {verifiedLow.id: verifiedLow});
    expect(clean.isProvisional, isFalse);
    expect(clean.uncertainty, 'LOW');

    final roughSpec = const ActionImpactSpec.perUnit(
      factorId: 'bottle',
      quantityUnit: 'use',
    );
    final rough = engine.estimate(spec: roughSpec, factors: factors);
    expect(rough.isProvisional, isTrue);
    expect(rough.uncertainty, 'HIGH');
  });
}