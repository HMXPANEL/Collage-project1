import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/state/providers.dart';
import '../../core/theme/ecoaction_theme.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/eco_icons.dart';
import '../../core/widgets/ui.dart';
import '../../domain/models/emission_factor.dart';

/// Profile hub: personal summary plus links to leaderboard, coach and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final streak = ref.watch(dashboardStatsProvider).value?.currentStreak ?? 0;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: profile == null
          ? CustomScrollView(
              slivers: [
                const EcoAppBar.medium(title: 'Profile'),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                const EcoAppBar.medium(title: 'Profile'),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Entrance(
                        child: EcoCard(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        EcoIcons.profile,
                                        color: scheme.onPrimaryContainer,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Eco profile',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _transportLabel(
                                                profile.transportBaseline),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (streak > 0) _StreakPill(streak: streak),
                                  ],
                                ),
                                if (profile.interests.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final name in profile.interests)
                                        EcoChip(
                                          label: emissionCategoryFromName(name)
                                              .label,
                                          icon: categoryIcon(
                                            emissionCategoryFromName(name),
                                          ),
                                          onSelected: (_) {},
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MiniStat(
                                        icon: Icons.eco_outlined,
                                        value: '${profile.interests.length}',
                                        label: 'Interests',
                                      ),
                                    ),
                                    Expanded(
                                      child: _MiniStat(
                                        icon: Icons.check_circle_outline,
                                        value: '${profile.habits.length}',
                                        label: 'Habits',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Your space',
                        subtitle: 'Everything for your journey',
                      ),
                      _LinkTile(
                        icon: Icons.school,
                        title: 'Community leaderboard',
                        subtitle: 'Demo ranking of peers and your college',
                        onTap: () => context.pushNamed(AppRoutes.community),
                      ),
                      _LinkTile(
                        icon: Icons.assistant,
                        title: 'Climate Coach',
                        subtitle: 'Offline, rules-based guidance',
                        onTap: () => context.pushNamed(AppRoutes.coach),
                      ),
                      _LinkTile(
                        icon: Icons.settings,
                        title: 'Settings',
                        subtitle: 'Appearance, region, reminders, data',
                        onTap: () => context.pushNamed(AppRoutes.settings),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  String _transportLabel(String? baseline) {
    if (baseline == null) return 'Travel preference not shared';
    return _transportLabels[baseline] ?? 'Travel preference';
  }

  static const _transportLabels = {
    'walk': 'Walk · bike or walk to commute',
    'cycle': 'Cycle · pedal-power commuter',
    'bus': 'Bus · public transit commuter',
    'scooter': 'Scooter · two-wheeler commuter',
    'car': 'Car · private vehicle commuter',
    'none': 'Minimal commuter',
  };
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EcoActionTheme.ember.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: EcoActionTheme.ember,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak-day streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EcoCard(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
