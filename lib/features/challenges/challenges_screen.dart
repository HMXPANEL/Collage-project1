import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/ecoaction_theme.dart';
import '../../core/widgets/eco_card.dart';
import '../../core/widgets/ui.dart';
import '../../domain/models/badge.dart';
import 'progress_engine.dart';

enum _ChallengeFilter { all, active, completed }

/// Challenges tab: current streak, filterable challenge progress, and the
/// badge collection. A lightweight celebration appears when a challenge is
/// newly completed.
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  _ChallengeFilter _filter = _ChallengeFilter.all;
  final Set<String> _knownCompleted = {};

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ChallengesSnapshot>>(
      challengesProvider,
      (previous, next) {
        final prev = previous?.valueOrNull;
        final nextValue = next.valueOrNull;
        if (prev == null || nextValue == null) return;
        final prevCompleted = {
          for (final c in prev.challenges)
            if (c.completed) c.challenge.id,
        };
        for (final c in nextValue.challenges) {
          if (c.completed &&
              !prevCompleted.contains(c.challenge.id) &&
              _knownCompleted.add(c.challenge.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showCelebration(c);
            });
          }
        }
      },
    );

    final snapshotAsync = ref.watch(challengesProvider);

    return Scaffold(
      body: switch (snapshotAsync) {
        AsyncData(value: final snapshot) => CustomScrollView(
            slivers: [
              const EcoAppBar.medium(title: 'Challenges'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Entrance(
                        child: _StreakCard(streak: snapshot.currentStreak)),
                    const SizedBox(height: 16),
                    _FilterTabs(
                      filter: _filter,
                      onChanged: (filter) => setState(() => _filter = filter),
                    ),
                    SectionHeader(
                      title: 'Active challenges',
                      subtitle: 'Rolling windows over the last days',
                    ),
                    if (snapshot.challenges.isEmpty)
                      EmptyState(
                        icon: Icons.emoji_events_outlined,
                        title: 'New challenges are coming soon.',
                        message:
                            'Check back later for fresh ways to build your '
                            'streak.',
                      )
                    else
                      for (final progress in _visible(snapshot))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Entrance(
                            delay: 0.05,
                            child: _ChallengeTile(progress: progress),
                          ),
                        ),
                    SectionHeader(
                      title: 'Badges',
                      subtitle: 'Milestones you earned',
                    ),
                    Entrance(child: _BadgeGrid(snapshot: snapshot)),
                  ]),
                ),
              ),
            ],
          ),
        AsyncError() => CustomScrollView(
            slivers: [
              const EcoAppBar.medium(title: 'Challenges'),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
              ),
            ],
          ),
        _ => CustomScrollView(
            slivers: [
              const EcoAppBar.medium(title: 'Challenges'),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
      },
    );
  }

  List<ChallengeWithProgress> _visible(ChallengesSnapshot snapshot) {
    return switch (_filter) {
      _ChallengeFilter.all => snapshot.challenges,
      _ChallengeFilter.active =>
        snapshot.challenges.where((c) => !c.completed).toList(),
      _ChallengeFilter.completed =>
        snapshot.challenges.where((c) => c.completed).toList(),
    };
  }

  void _showCelebration(ChallengeWithProgress challenge) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _CelebrationDialog(challenge: challenge),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.filter, required this.onChanged});

  final _ChallengeFilter filter;
  final ValueChanged<_ChallengeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        children: [
          for (final option in _ChallengeFilter.values)
            EcoChip(
              label: switch (option) {
                _ChallengeFilter.all => 'All',
                _ChallengeFilter.active => 'Active',
                _ChallengeFilter.completed => 'Completed',
              },
              selected: filter == option,
              onSelected: (_) => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = streak > 0;
    return EcoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: on
                    ? EcoActionTheme.ember.withValues(alpha: 0.2)
                    : scheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 30,
                color: on ? EcoActionTheme.ember : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedNumber(
                    value: streak.toDouble(),
                    format: (v) => v.round().toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: on ? EcoActionTheme.ember : scheme.onSurface,
                        ),
                  ),
                  Text(
                    on
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: done
                        ? scheme.tertiaryContainer
                        : scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    challengeIcon(progress.challenge.icon),
                    size: 22,
                    color: done ? scheme.onTertiaryContainer : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    progress.challenge.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (done)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: 14,
                          color: scheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              progress.challenge.description,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AnimatedProgressBar(
                    value: progress.fraction,
                    color: done ? scheme.tertiary : scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${done ? progress.target : progress.progress}'
                  '/${progress.target}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.snapshot});

  final ChallengesSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (snapshot.badges.isEmpty) {
      return EcoCard(
        child: Text(
          'Your first badge will appear here.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
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
    final color = earned ? scheme.primary : scheme.onSurfaceVariant;
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: earned ? 1 : 0.9),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: earned ? 1 : 0.55,
              child: Transform.scale(scale: t, child: child),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(badgeIcon(badge.icon), size: 40, color: color),
                if (!earned)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.lock,
                      size: 14,
                      color: Colors.black45,
                    ),
                  ),
              ],
            ),
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

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.challenge});

  final ChallengeWithProgress challenge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant, width: 0.7),
            boxShadow: [
              BoxShadow(
                color: scheme.tertiary.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 38,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Challenge complete!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'You did it.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                challenge.challenge.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.tertiary,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Nice!'),
              ),
            ],
          ),
        ),
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
