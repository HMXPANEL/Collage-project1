import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/eco_motion.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/ui.dart';

/// Brand reveal shown while the local database loads, before routing to
/// onboarding or the home shell. Also surfaces load failures instead of a
/// blank screen. The reveal is short by design.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Slow, subtle breathing/float loop behind the logo. Runs only while this
  /// screen is on stage (it is, by construction, the first route).
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final scheme = Theme.of(context).colorScheme;
    final reduced = EcoMotion.reduced(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _logo(reduced),
                const SizedBox(height: 20),
                Entrance(delay: 0.25, child: _title()),
                const SizedBox(height: 8),
                Entrance(delay: 0.45, child: _tagline(scheme)),
                const SizedBox(height: 40),
                if (profileState.isLoading || profileState.isRefreshing) ...[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
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
      ),
    );
  }

  Widget _logo(bool reduced) {
    final scheme = Theme.of(context).colorScheme;
    final reveal = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.eco, size: 52, color: scheme.primary),
      ),
    );
    if (reduced) return reveal;
    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, -3 * _float.value),
        child: reveal,
      ),
    );
  }

  Widget _title() {
    return Text(
      'EcoAction',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
    );
  }

  Widget _tagline(ColorScheme scheme) {
    return Text(
      'Small actions add up to real change.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
    );
  }
}
