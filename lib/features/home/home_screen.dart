import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/estimate_chip.dart';
import '../../core/precision/formatting.dart';
import '../../domain/models/action_log.dart';
import '../../domain/models/emission_factor.dart';

/// Home tab: lifetime impact, current streak and today's logged actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('EcoAction')),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.refresh(dashboardStatsProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const _RangeIntroCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'CO₂e avoided',
                          value: Formatting.compactKg(stats.totalKg),
                          icon: Icons.eco,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Actions',
                          value: '${stats.totalActions}',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Streak',
                          value: '${stats.currentStreak}',
                          icon: Icons.local_fire_department,
                          iconTinted: stats.currentStreak > 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Today', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (stats.todayLogs.isEmpty)
                    _EmptyToday()
                  else
                    for (final log in stats.todayLogs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TodayTile(log: log),
                      ),
                ],
              ),
            ),
    );
  }
}

class _RangeIntroCard extends StatelessWidget {
  const _RangeIntroCard();

  @override
  Widget build(BuildContext context) {
    return const EcoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your climate journey'),
          SizedBox(height: 4),
          Text(
            'Log actions to see how much CO₂e you avoid and build your streak.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconTinted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool iconTinted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final numberStyle = Theme.of(context).textTheme.headlineSmall;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final iconColor = iconTinted ? const Color(0xFFEF6C00) : scheme.primary;
    return EcoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: numberStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: labelStyle?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EcoCard(
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, size: 40),
          const SizedBox(height: 8),
          const Text('Nothing logged yet today.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/actions'),
            icon: const Icon(Icons.add),
            label: const Text('Browse actions'),
          ),
        ],
      ),
    );
  }
}

class _TodayTile extends StatelessWidget {
  const _TodayTile({required this.log});

  final ActionLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EcoCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(categoryIcon(emissionCategoryFromName(log.category)),
            color: scheme.primary),
        title: Text(log.actionTitle),
        trailing: EstimateChip(estimateInKg: log.kgCo2e),
      ),
    );
  }
}
