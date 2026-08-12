import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/ui.dart';
import '../../core/precision/formatting.dart';
import '../../domain/engines/impact_engine.dart';
import '../../domain/models/action_log.dart';
import '../../domain/models/eco_action.dart';
import '../../domain/models/emission_factor.dart';

/// Detail + logging screen for one catalog action.
class ActionLogScreen extends ConsumerStatefulWidget {
  const ActionLogScreen({super.key, required this.actionId});

  final String actionId;

  @override
  ConsumerState<ActionLogScreen> createState() => _ActionLogScreenState();
}

class _ActionLogScreenState extends ConsumerState<ActionLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  bool _submitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(actionsProvider).value;
    final factors = ref.watch(emissionFactorsProvider).value;

    EcoAction? action;
    if (actions != null) {
      for (final a in actions) {
        if (a.id == widget.actionId) {
          action = a;
          break;
        }
      }
    }

    if (action == null || factors == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final quantity = double.tryParse(_quantityController.text.trim());
    ImpactEstimate? estimate;
    if (quantity != null && quantity > 0) {
      estimate = const ImpactEngine().estimate(
        spec: action.impact,
        factors: factors,
        quantity: quantity,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            EcoAppBar.medium(title: action.title),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  EcoCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  categoryIcon(action.category),
                                  color: scheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  action.category.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            action.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.eco_outlined,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Why it helps: ${action.whyItHelps}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'How much',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: action.impact.quantityLabel,
                      prefixIcon: const Icon(Icons.straighten),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a quantity greater than 0';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your estimated impact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  EcoCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: estimate == null
                          ? Text(
                              'Enter a quantity to see your impact.',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedNumber(
                                  value: estimate.kgCo2e,
                                  format: (v) => '~${Formatting.compactKg(v)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: scheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Estimated CO₂e avoided',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  estimate.isProvisional
                                      ? 'Approximate estimate based on a '
                                          'provisional factor.'
                                      : 'Estimate based on standard emission factors.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _log,
                    icon: const Icon(Icons.check),
                    label: const Text('Log this action'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _log() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final actions = ref.read(actionsProvider).value;
    final factors = ref.read(emissionFactorsProvider).value;
    if (actions == null || factors == null) return;

    EcoAction? action;
    for (final a in actions) {
      if (a.id == widget.actionId) {
        action = a;
        break;
      }
    }
    if (action == null) return;

    final quantity = double.parse(_quantityController.text.trim());
    final estimate = const ImpactEngine().estimate(
      spec: action.impact,
      factors: factors,
      quantity: quantity,
    );

    setState(() => _submitting = true);
    final repository = await ref.read(actionLogRepositoryProvider.future);
    await repository.add(
      ActionLog(
        actionId: action.id,
        actionTitle: action.title,
        category: action.category.name,
        happenedOn: DateTime.now(),
        kgCo2e: estimate.kgCo2e,
        quantity: estimate.quantity,
        inputUnit: estimate.quantityUnit,
        provisional: estimate.isProvisional,
      ),
    );
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(impactProvider);
    ref.invalidate(challengesProvider);

    if (!mounted) return;
    final message = 'Logged ~${Formatting.compactKg(estimate.kgCo2e)} CO₂e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    context.pop();
  }
}
