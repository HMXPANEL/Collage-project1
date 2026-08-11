import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/eco_icons.dart';

/// Profile hub: personal summary plus links to settings, leaderboard, coach
/// and data management.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(
                                EcoIcons.profile,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _transportLabel(profile.transportBaseline),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _summaryRow(
                            Icons.eco, '${profile.interests.length} interests'),
                        _summaryRow(Icons.eco_outlined,
                            '${profile.habits.length} habits committed'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
              ],
            ),
    );
  }

  Widget _summaryRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
