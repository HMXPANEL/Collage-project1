import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/widgets/eco_card.dart';
import '../../domain/models/badge.dart';
import 'progress_engine.dart';

/// Challenges tab: current streak, active challenges with progress, and the
/// badge collection.
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: switch (snapshotAsync) {
        AsyncData(value: final snapshot) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StreakCard(streak: snapshot.currentStreak),
              const SizedBox(height: 16),
              Text(
                'Active challenges',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final progress in snapshot.challenges)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChallengeTile(progress: progress),
                ),
              const SizedBox(height: 16),
              Text('Badges', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _BadgeGrid(snapshot: snapshot),
            ],
          ),
        AsyncError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                const Text('Could not load challenges.'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(challengesProvider),
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EcoCard(
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 32,
            color: streak > 0 ? const Color(0xFFEF6C00) : scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  streak > 0
                      ? '${_dayLabel(streak)} streak — keep it going!'
                      : 'No streak yet. Log an action to start one.',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dayLabel(int n) => n == 1 ? 'day' : 'days';
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.progress});

  final ChallengeWithProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = progress.completed;
    return EcoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                challengeIcon(progress.challenge.icon),
                size: 28,
                color: done ? scheme.tertiary : scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress.challenge.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (done)
                Chip(
                  label: const Text('Done', style: TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: scheme.tertiaryContainer,
                  labelStyle: TextStyle(color: scheme.onTertiaryContainer),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            progress.challenge.description,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: done ? 1.0 : progress.fraction,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${done ? progress.target : progress.progress}/${progress.target}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.snapshot});

  final ChallengesSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 16,
        children: [
          for (final badge in snapshot.badges)
            _BadgeTile(badge: badge, earned: snapshot.isEarned(badge.id)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earned});

  final Badge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = earned ? scheme.primary : scheme.outline;
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                badgeIcon(badge.icon),
                size: 38,
                color: color,
              ),
              if (!earned)
                const Icon(Icons.lock, size: 16, color: Colors.black45),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: earned ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            earned ? 'Earned' : 'Locked',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Resolves the semantic challenge icon keys from the catalog.
IconData challengeIcon(String key) {
  return switch (key) {
    'green_week' => Icons.eco,
    'no_plastic' => Icons.delete_sweep_outlined,
    'travel' => Icons.directions_bus,
    _ => Icons.flag_outlined,
  };
}

/// Resolves the semantic badge icon keys from the catalog.
IconData badgeIcon(String key) {
  return switch (key) {
    'first_step' => Icons.directions_walk,
    'actions_25' => Icons.bolt,
    'streak_7' => Icons.local_fire_department,
    'challenge_done' => Icons.emoji_events,
    _ => Icons.military_tech,
  };
}
