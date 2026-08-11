import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/precision/formatting.dart';
import '../../domain/models/emission_factor.dart';

/// Impact tab: lifetime total, a dependency-free 7-day bar chart, and the
/// category breakdown of everything avoided so far.
class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(impactProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Impact')),
      body: switch (summaryAsync) {
        AsyncData(value: final summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EcoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '~${Formatting.compactKg(summary.totalKg)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total CO₂e avoided · ${summary.totalActions} actions',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Last 7 days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _WeeklyBars(
                daily: summary.lastSevenDaysKg,
                today: DateTime.now(),
              ),
              const SizedBox(height: 16),
              Text(
                'By category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _CategoryBreakdown(categoryKg: summary.categoryKg),
            ],
          ),
        AsyncError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                const Text('Could not load your impact history.'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(impactProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.daily, required this.today});

  final List<double> daily;
  final DateTime today;

  static String _weekdayShort(int weekday) {
    return const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = daily.fold(0.0, (a, b) => b > a ? b : a);
    const maxBarHeight = 96.0;

    return EcoCard(
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < daily.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (daily[i] > 0)
                      Text(
                        Formatting.compactKg(daily[i]),
                        style: const TextStyle(fontSize: 10),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      height: max <= 0 ? 0 : maxBarHeight * daily[i] / max,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weekdayShort(
                        today.subtract(Duration(days: 6 - i)).weekday,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categoryKg});

  final Map<String, double> categoryKg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (categoryKg.isEmpty) {
      return EcoCard(
        child: Text(
          'Nothing logged yet. Your first action will show up here.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    final total = categoryKg.values.fold(0.0, (a, b) => a + b);

    return EcoCard(
      child: Column(
        children: [
          for (final entry in categoryKg.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    categoryIcon(emissionCategoryFromName(entry.key)),
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emissionCategoryFromName(entry.key).label,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatting.compactKg(entry.value),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
