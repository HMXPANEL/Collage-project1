import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/providers.dart';
import '../../core/theme/ecoaction_theme.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/estimate_chip.dart';
import '../../core/widgets/ui.dart';
import '../../core/precision/formatting.dart';
import '../../domain/models/action_log.dart';
import '../../domain/models/emission_factor.dart';

/// Home tab: lifetime impact, today's stats and logged actions.
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _GreetingHeader(),
                  const SizedBox(height: 16),
                  _HeroCard(totalKg: stats.totalKg),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.eco,
                          label: 'CO₂e avoided',
                          value: AnimatedNumber(
                            value: stats.todayKg,
                            format: Formatting.compactKg,
                            style: _statNumberStyle(context),
                          ),
                          onTap: () => context.go('/impact'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Actions',
                          value: AnimatedNumber(
                            value: stats.todayLogs.length.toDouble(),
                            format: (v) => v.round().toString(),
                            style: _statNumberStyle(context),
                          ),
                          onTap: () => context.go('/actions'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          icon: Icons.local_fire_department,
                          iconColor: stats.currentStreak > 0
                              ? EcoActionTheme.ember
                              : null,
                          label: 'Streak',
                          value: AnimatedNumber(
                            value: stats.currentStreak.toDouble(),
                            format: (v) => v.round().toString(),
                            style: _statNumberStyle(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Entrance(delay: 0.1, child: _CoachCard()),
                  SectionHeader(
                    title: 'Today',
                    subtitle: 'Your logged actions today',
                  ),
                  if (stats.todayLogs.isEmpty)
                    EmptyState(
                      icon: Icons.eco_outlined,
                      title: 'Nothing logged yet today.',
                      message:
                          'Log one small action to see it here and keep your '
                          'streak alive.',
                      actionLabel: 'Browse actions',
                      onAction: () => context.go('/actions'),
                    )
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

  static TextStyle? _statNumberStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning!'
        : hour < 17
            ? 'Good afternoon!'
            : 'Good evening!';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Small steps, big impact.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.totalKg});

  final double totalKg;

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
          Row(
            children: [
              Icon(Icons.eco, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your climate journey',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedNumber(
            value: totalKg,
            format: Formatting.compactKg,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'lifetime CO₂e avoided · estimate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EcoCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.assistant, color: scheme.primary, size: 20),
        ),
        title: const Text('Climate Coach'),
        subtitle: const Text('Offline guidance for your next step'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/coach'),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon(emissionCategoryFromName(log.category)),
                color: scheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.actionTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Completed today',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            EstimateChip(estimateInKg: log.kgCo2e),
          ],
        ),
      ),
    );
  }
}
