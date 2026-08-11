import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/ui.dart';
import '../../core/precision/formatting.dart';
import '../../domain/models/emission_factor.dart';
import 'impact_engine.dart';

const _rangeOptions = [
  (days: 7, label: '7D'),
  (days: 30, label: '30D'),
  (days: 90, label: '3M'),
  (days: 365, label: '1Y'),
  (days: null, label: 'All'),
];

/// Impact tab: animated hero total, timeframe controls, a dependency-free
/// bar chart, the category breakdown, and a link to the estimation method.
class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(impactProvider);
    final selected = ref.watch(impactRangeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Impact')),
      body: switch (summaryAsync) {
        AsyncData(value: final summary) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeroCard(summary: summary),
              const SizedBox(height: 12),
              _RangePills(
                selected: selected,
                onSelected: (days) {
                  ref.read(impactRangeProvider.notifier).state = days;
                },
              ),
              SectionHeader(
                title: _rangeTitle(selected),
                subtitle: 'Estimated CO₂e avoided per day',
              ),
              if (summary.totalKg <= 0)
                EmptyState(
                  icon: Icons.insights,
                  title: 'Your impact story starts here.',
                  message: 'Log your first action to see your progress.',
                )
              else
                Entrance(
                  child: _ImpactChart(
                    buckets: summary.dailyKg.isEmpty
                        ? summary.lastSevenDaysKg
                        : summary.dailyKg,
                    startDay: DateTime.now().subtract(
                      Duration(
                        days: (summary.dailyKg.isEmpty
                                    ? summary.lastSevenDaysKg
                                    : summary.dailyKg)
                                .length -
                            1,
                      ),
                    ),
                  ),
                ),
              SectionHeader(
                title: 'By category',
                subtitle: 'Estimates based on emission factors',
              ),
              _CategoryBreakdown(categoryKg: summary.categoryKg),
              const SizedBox(height: 8),
              _HowWeEstimateRow(),
            ],
          ),
        AsyncError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: scheme.error),
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

  static String _rangeTitle(int? days) => switch (days) {
        7 => 'Last 7 days',
        30 => 'Last 30 days',
        90 => 'Last 3 months',
        365 => 'Last year',
        null => 'All time',
        _ => 'Last $days days',
      };
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final ImpactSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant, width: 0.7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surfaceContainerLow],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifetime total',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          AnimatedNumber(
            value: summary.totalKg,
            format: (v) => '~${Formatting.compactKg(v)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total CO₂e avoided · ${summary.totalActions} actions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _RangePills extends StatelessWidget {
  const _RangePills({required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        children: [
          for (final option in _rangeOptions)
            EcoChip(
              label: option.label,
              selected: selected == option.days,
              onSelected: (_) => onSelected(option.days),
            ),
        ],
      ),
    );
  }
}

class _ImpactChart extends StatelessWidget {
  const _ImpactChart({required this.buckets, required this.startDay});

  final List<double> buckets;
  final DateTime startDay;

  static const double _maxBarHeight = 110;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bars = _buildBars();
    final max = bars.fold(0.0, (a, b) => b.value > a ? b.value : a);

    return EcoCard(
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < bars.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (bars.length <= 15 && bars[i].value > 0)
                        Text(
                          Formatting.compactKg(bars[i].value),
                          style: TextStyle(
                            fontSize: 9,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: max <= 0
                              ? 0
                              : (bars[i].value / max).clamp(0.0, 1.0),
                        ),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) => Container(
                          height: (_maxBarHeight * t).clamp(0.0, _maxBarHeight),
                          decoration: BoxDecoration(
                            color: i == bars.length - 1
                                ? scheme.tertiary
                                : scheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (bars[i].label.isNotEmpty)
                        Text(
                          bars[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Collapses long windows into at most ~30 bars so the chart stays
  /// readable on a phone.
  List<_ChartBar> _buildBars() {
    const maxBars = 30;
    if (buckets.length <= maxBars) {
      return [
        for (var i = 0; i < buckets.length; i++)
          _ChartBar(buckets[i], _dayLabel(i)),
      ];
    }
    final chunk = (buckets.length / maxBars).ceil();
    final bars = <_ChartBar>[];
    for (var i = 0; i < buckets.length; i += chunk) {
      var sum = 0.0;
      for (var j = i; j < i + chunk && j < buckets.length; j++) {
        sum += buckets[j];
      }
      bars.add(_ChartBar(sum, _monthLabel(i)));
    }
    return bars;
  }

  String _dayLabel(int index) {
    return '${startDay.add(Duration(days: index)).day}';
  }

  String _monthLabel(int index) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[startDay.add(Duration(days: index)).month];
  }
}

class _ChartBar {
  const _ChartBar(this.value, this.label);

  final double value;
  final String label;
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
    final entries = categoryKg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return EcoCard(
      child: Column(
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcon(emissionCategoryFromName(entry.key)),
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emissionCategoryFromName(entry.key).label,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedProgressBar(value: entry.value / total),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Formatting.tinyKg(entry.value),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
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

class _HowWeEstimateRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EcoCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.functions),
        title: const Text('How we estimate'),
        subtitle: const Text('Where the numbers come from'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(AppRoutes.methodology),
      ),
    );
  }
}
