import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';

/// App information and credits.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 64, color: scheme.primary),
              const SizedBox(height: 12),
              Text('EcoAction',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('v1.0.0', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Text(
                'A local-first climate action tracker. Track what you do, '
                'estimate your CO₂e impact, build greener habits.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.pushNamed(AppRoutes.methodology),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Read how we estimate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}