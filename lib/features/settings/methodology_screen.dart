import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// How estimates work, written in plain language.
class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How we estimate')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: 'What an estimate is',
            text: 'Each action you log is multiplied by an emission factor: a '
                'number describing kg of CO₂e per unit (e.g. per kWh, per km, '
                'per kg). The result is the CO₂e your action avoided.',
          ),
          _section(
            title: 'Where factors come from',
            text: 'Factors are sourced from published emission inventories and '
                'research, with a source name and reference shown per factor. '
                'Regional factors (currently India and global) are kept '
                'separate so values are never mixed across regions.',
          ),
          _section(
            title: 'Provisional vs verified',
            text: 'Factors we are more confident about are marked verified. '
                'Factors needing more evidence are provisional, and any log '
                'that used a provisional factor is flagged in your history so '
                'you can treat the numbers accordingly.',
          ),
          _section(
            title: 'Uncertainty',
            text: 'Every factor carries an uncertainty level (LOW / MEDIUM / '
                'HIGH). Estimates are directional guidance for habit change, '
                'not a carbon audit. View factor details from the action log '
                'to see the source of any specific number.',
          ),
          const SizedBox(height: 12),
          Text(
            'App version: v1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Data region default: ${AppConstants.defaultRegion}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
