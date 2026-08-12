import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/estimate_chip.dart';
import '../../core/widgets/ui.dart';
import '../../domain/engines/impact_engine.dart';
import '../../domain/models/eco_action.dart';
import '../../domain/models/emission_factor.dart';

/// Action catalog grouped by category. Tapping an action opens its log screen.
class ActionsScreen extends ConsumerWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionsProvider);
    final factorsAsync = ref.watch(emissionFactorsProvider);

    return Scaffold(
      body: switch ((actionsAsync, factorsAsync)) {
        (AsyncData(value: final actions), AsyncData(value: final factors)) =>
          CustomScrollView(
            slivers: [
              const EcoAppBar.medium(title: 'Take Action'),
              _CatalogSliver(actions: actions, factors: factors),
            ],
          ),
        (AsyncError(error: final error), _) ||
        (_, AsyncError(error: final error)) =>
          CustomScrollView(
            slivers: [
              const EcoAppBar.medium(title: 'Take Action'),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _CatalogError(error: error, ref: ref),
              ),
            ],
          ),
        _ => CustomScrollView(
            slivers: [
              const EcoAppBar.medium(title: 'Take Action'),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
      },
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error, required this.ref});

  final Object error;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          const Text('Could not load the action catalog.'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {
              ref.invalidate(actionsProvider);
              ref.invalidate(emissionFactorsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CatalogSliver extends StatelessWidget {
  const _CatalogSliver({required this.actions, required this.factors});

  final List<EcoAction> actions;
  final Map<String, EmissionFactor> factors;

  @override
  Widget build(BuildContext context) {
    final grouped = {
      for (final category in EmissionCategory.values) category: <EcoAction>[],
    };
    for (final action in actions) {
      grouped[action.category]!.add(action);
    }
    final engine = const ImpactEngine();

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          for (final category in EmissionCategory.values)
            if (grouped[category]!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  category.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final action in grouped[category]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActionTile(
                    action: action,
                    defaultEstimate: engine.estimate(
                      spec: action.impact,
                      factors: factors,
                    ),
                  ),
                ),
            ],
        ]),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.defaultEstimate});

  final EcoAction action;
  final ImpactEstimate defaultEstimate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EcoCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(categoryIcon(action.category), color: scheme.primary),
        title: Text(action.title),
        subtitle: Text(
          action.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: EstimateChip(estimateInKg: defaultEstimate.kgCo2e),
        onTap: () => context.push('/actions/${action.id}'),
      ),
    );
  }
}
