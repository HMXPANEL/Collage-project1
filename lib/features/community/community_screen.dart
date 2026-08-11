import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import 'community_engine.dart';

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
        data: (snapshot) {
          final you = snapshot.currentUser;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _DemoNotice(),
              const SizedBox(height: 16),
              _CollegeCard(collegeTotalKg: snapshot.collegeTotalKg),
              const SizedBox(height: 16),
              if (you != null)
                _YourRankCard(you: you)
              else
                const Center(
                  child: Text('Log your first action to join the board'),
                ),
              const SizedBox(height: 16),
              Text(
                'Leaderboard',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final member in snapshot.members) _RankTile(member: member),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Demo data — peers shown are sample profiles, not real people. '
        'This simulates how a college leaderboard will work once live servers connect.',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _CollegeCard extends StatelessWidget {
  const _CollegeCard({required this.collegeTotalKg});

  final double collegeTotalKg;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.school),
        title: const Text('Your demo college'),
        subtitle: Text(
            '${collegeTotalKg.toStringAsFixed(1)} kg of CO₂e avoided together on this demo board'),
      ),
    );
  }
}

class _YourRankCard extends StatelessWidget {
  const _YourRankCard({required this.you});

  final CommunityMember you;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: CircleAvatar(
          child: Text('#${you.rank}'),
        ),
        title: const Text('You'),
        subtitle: Text(
            '${you.totalKg.toStringAsFixed(1)} kg avoided · ${you.totalActions} actions'),
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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.isYou ? scheme.primary : scheme.surfaceVariant,
        child: Text('#${member.rank}'),
      ),
      title: Text(member.isYou ? 'You (demo)' : member.name),
      subtitle: Text(member.college),
      trailing: Text('${member.totalKg.toStringAsFixed(1)} kg'),
      selected: member.isYou,
      tileColor: member.isYou ? scheme.primaryContainer.withOpacity(0.3) : null,
    );
  }
}
