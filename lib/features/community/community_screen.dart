import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/ecoaction_theme.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/ui.dart';
import 'community_engine.dart';

/// Demo community leaderboard. Ranks the user against seeded peers, clearly
/// labelled so nobody mistakes it for a live college board.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(communityProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load: $err')),
        data: (data) {
          final you = data.currentUser;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Entrance(child: _DemoNotice()),
              const SizedBox(height: 12),
              Entrance(
                delay: 0.06,
                child: _CampusCard(collegeTotalKg: data.collegeTotalKg),
              ),
              const SizedBox(height: 12),
              if (you != null)
                Entrance(delay: 0.12, child: _YourRankCard(you: you))
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Log your first action to join the board'),
                  ),
                ),
              SectionHeader(
                title: 'Leaderboard',
                subtitle: data.isDemo
                    ? 'Demo peers — not real people'
                    : 'Ranked by CO₂e avoided',
              ),
              for (var i = 0; i < data.members.length; i++)
                Entrance(
                  delay: 0.15 + (i * 0.04),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RankTile(member: data.members[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo data — peers shown are sample profiles, not real people. '
              'This simulates a college leaderboard for a future live server.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.collegeTotalKg});

  final double collegeTotalKg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant, width: 0.7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surfaceContainerLow],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school, color: scheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community impact',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your demo college · all members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedNumber(
                value: collegeTotalKg,
                format: (v) => '${v.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
              ),
              Text(
                'CO₂e avoided',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YourRankCard extends StatelessWidget {
  const _YourRankCard({required this.you});

  final CommunityMember you;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary,
            child: Text(
              'Y',
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${you.rank} on this demo board',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedNumber(
                value: you.totalKg,
                format: (v) => '${v.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
              ),
              Text(
                '${you.totalActions} actions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isYou = member.isYou;
    return EcoCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: _rankBadge(scheme),
        title: Text(
          isYou ? 'You (demo)' : member.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          isYou ? 'Your position on this board' : member.college,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedNumber(
              value: member.totalKg,
              format: (v) => '${v.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              '${member.totalActions} actions',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        tileColor:
            isYou ? scheme.primaryContainer.withValues(alpha: 0.3) : null,
      ),
    );
  }

  Widget _rankBadge(ColorScheme scheme) {
    final rank = member.rank;
    final Widget child;
    final Color? background;
    final Color? foreground;
    if (rank == 1) {
      child = const Icon(Icons.emoji_events, size: 18);
      background = EcoActionTheme.ember;
      foreground = const Color(0xFF3B2700);
    } else {
      child =
          Text('$rank', style: const TextStyle(fontWeight: FontWeight.w800));
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: member.isYou ? scheme.primary : background,
      child: IconTheme(
        data: IconThemeData(
          color: member.isYou ? scheme.onPrimary : foreground,
          size: 18,
        ),
        child: child,
      ),
    );
  }
}
