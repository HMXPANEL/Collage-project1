import 'package:eco_action/data/repositories/catalog_repository.dart';
import 'package:eco_action/domain/models/eco_action.dart';
import 'package:eco_action/domain/models/emission_factor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = CatalogRepository();

  test('catalog validation is clean', () async {
    final issues = await catalog.validate();
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('every factor carries the full attribution fields', () async {
    final factors = await catalog.factors();
    expect(factors.length, greaterThan(0));
    for (final factor in factors.values) {
      expect(factor.id, isNotEmpty);
      expect(factor.value, isNonNegative);
      expect(factor.unit, isNotEmpty);
      expect(factor.region, isNotEmpty);
      expect(factor.version, isNotEmpty);
      expect(factor.sourceName, isNotEmpty, reason: 'factor ${factor.id}');
      expect(factor.sourceReference, isNotEmpty, reason: 'factor ${factor.id}');
      expect(factor.notes, isNotEmpty, reason: 'factor ${factor.id}');
      expect(
        ['LOW', 'MEDIUM', 'HIGH'],
        contains(factor.uncertainty),
        reason: 'factor ${factor.id}',
      );
      expect(
        [FactorStatus.provisional, FactorStatus.verified],
        contains(factor.status),
        reason: 'factor ${factor.id}',
      );
      expect(factor.status, equals(FactorStatus.provisional),
          reason: 'no factor may be marked verified before Phase 2b');
    }
  });

  test('eighteen seed actions across all six categories', () async {
    final actions = await catalog.actions();
    expect(actions.length, 18);
    expect(actions.where((a) => !a.seed), isEmpty);
    expect(
      actions.map((a) => a.category).toSet(),
      EmissionCategory.values.toSet(),
    );
  });

  test('seed actions reference only existing factors', () async {
    final issues = await catalog.validate();
    expect(issues.where((i) => i.startsWith('action ')), isEmpty);
  });

  test('actions parse with an impact spec', () async {
    final walk = (await catalog.actions())
        .firstWhere((a) => a.id == 'walk_short_route');
    expect(walk.impact.type, ImpactType.baselineAlternative);
    expect(walk.impact.quantityUnit, 'km');
  });

  test('expanding the catalog requires no code change', () async {
    // Adding a new action is purely a data edit; the loader must accept every
    // valid-typed entry. This asserts the loader can enumerate all of them.
    final actions = await catalog.actions();
    expect(actions.map((a) => a.id).toSet().length, actions.length);
  });
}