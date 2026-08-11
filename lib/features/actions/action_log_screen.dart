import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/precision/formatting.dart';
import '../../domain/engines/impact_engine.dart';
import '../../domain/models/action_log.dart';
import '../../domain/models/eco_action.dart';

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
        appBar: AppBar(),
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

    return Scaffold(
      appBar: AppBar(title: Text(action.title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EcoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.description),
                  const SizedBox(height: 8),
                  Text(
                    'Why it helps: ${action.whyItHelps}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: action.impact.quantityLabel,
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
            const SizedBox(height: 16),
            EcoCard(
              child: estimate == null
                  ? const Text('Enter a quantity to see your impact.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated CO₂e avoided'),
                        const SizedBox(height: 4),
                        Text(
                          '~${Formatting.compactKg(estimate.kgCo2e)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (estimate.isProvisional)
                          const Text(
                            'Approximate estimate based on a provisional '
                            'factor.',
                            style: TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _log,
              icon: const Icon(Icons.check),
              label: const Text('Log this action'),
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
