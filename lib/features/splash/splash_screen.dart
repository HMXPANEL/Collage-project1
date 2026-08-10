import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';

/// Shown while the local database loads, before routing to onboarding or the
/// home shell. Also surfaces load failures instead of a blank screen.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text('EcoAction',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              if (profileState.isLoading || profileState.isRefreshing) ...[
                const CircularProgressIndicator(),
              ] else if (profileState.hasError) ...[
                Text(
                  'Could not open local data. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
