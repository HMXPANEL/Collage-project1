import 'package:flutter/material.dart';

/// Temporary bootstrap screen shown until real feature screens are built
/// in the design-system phase.
class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, size: 72, color: colors.primary),
                const SizedBox(height: 16),
                Text('EcoAction', style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Foundation is ready.\nScreens arrive in the next phases.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}