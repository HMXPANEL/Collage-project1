import 'package:flutter/material.dart';

import '../../core/widgets/ui.dart';

/// Local-first privacy statement. Plain text, no external services.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const EcoAppBar.medium(title: 'Privacy'),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Your data stays on this device.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'EcoAction is designed to be private by default. Everything you '
                  'log — your actions, profile, badges and challenge progress — is '
                  'stored only in the local database on your phone. We have no '
                  'servers and no analytics. Nothing is ever uploaded, sold, or '
                  'shared.',
                  style: body,
                ),
                const SizedBox(height: 16),
                _point(context, Icons.storage, 'Local storage',
                    'All data lives in an on-device database. Uninstall the app and it is gone.'),
                _point(context, Icons.offline_bolt, 'Fully offline',
                    'The app, including the climate coach, works without an internet connection.'),
                _point(
                    context,
                    Icons.folder_copy_outlined,
                    'You stay in control',
                    'Export a backup anytime to keep a copy of your data, and delete everything whenever you want.'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _point(
    BuildContext context,
    IconData icon,
    String title,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
