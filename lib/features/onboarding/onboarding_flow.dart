import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/category_icon.dart';
import '../../domain/models/emission_factor.dart';
import '../../domain/models/onboarding_habits.dart';
import '../../domain/models/user_profile.dart';

const _transportOptions = [
  (label: 'Walk', value: 'walk', icon: Icons.directions_walk),
  (label: 'Cycle', value: 'cycle', icon: Icons.directions_bike),
  (label: 'Bus', value: 'bus', icon: Icons.directions_bus),
  (label: 'Scooter', value: 'scooter', icon: Icons.two_wheeler),
  (label: 'Car', value: 'car', icon: Icons.directions_car),
  (label: 'Rarely commute', value: 'none', icon: Icons.home_outlined),
];

/// Welcome + guided profile questions. Saves a complete [UserProfile] and
/// lets the router redirect to the home shell.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _commuteController = TextEditingController();
  final Set<EmissionCategory> _interests = {};
  final Map<String, bool> _habits = {
    for (final habit in onboardingHabits) habit.id: false,
  };
  int _step = 0;
  String? _transportBaseline;
  bool _saving = false;

  @override
  void dispose() {
    _commuteController.dispose();
    super.dispose();
  }

  static const int _questionCount = 4;
  static const int _completionStep = _questionCount;

  void _advance() {
    if (_step < _completionStep) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final commute = double.tryParse(_commuteController.text.trim());
    final profile = UserProfile(
      region: AppConstants.defaultRegion,
      transportBaseline: _transportBaseline,
      dailyCommuteKm: commute,
      interests: _interests.map((c) => c.name).toList(),
      habits: {
        for (final entry in _habits.entries)
          if (entry.value) entry.key: 'yes',
      },
      onboarded: true,
    );
    await ref.read(profileProvider.notifier).save(profile);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _saving ? null : () => setState(() => _step--),
                tooltip: 'Back',
              ),
        title: const Text('Welcome'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_step >= 1 && _step <= _questionCount)
                _ProgressDots(total: _questionCount, current: _step),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: _page(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page() {
    return switch (_step) {
      0 => const _Welcome(key: ValueKey('welcome')),
      1 => _transportPage(key: const ValueKey('transport')),
      2 => _interestsPage(key: const ValueKey('interests')),
      3 => _habitsPage(key: const ValueKey('habits')),
      _ => const _DonePage(key: ValueKey('done')),
    };
  }

  Widget _footer() {
    final isLast = _step == _completionStep;
    final label = _saving
        ? 'Saving…'
        : switch (_step) {
            0 => 'Get Started',
            4 => 'Start My Journey',
            _ => 'Continue',
          };
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_step == 0) const Spacer(),
        FilledButton.icon(
          onPressed: _saving ? null : _advance,
          icon: Icon(isLast ? Icons.eco : Icons.arrow_forward),
          label: Text(label),
        ),
      ],
    );
  }

  Widget _transportPage({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeading(
          'How do you usually travel?',
          'Pick the option that sounds most like you.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in _transportOptions)
              _OptionCard(
                label: option.label,
                icon: option.icon,
                selected: _transportBaseline == option.value,
                onTap: () {
                  setState(() {
                    _transportBaseline = _transportBaseline == option.value
                        ? null
                        : option.value;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        _pageHeading(
          'Daily distance to college or work',
          'Optional — used to size your travel impact.',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commuteController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 6',
            prefixIcon: Icon(Icons.straighten),
            suffixText: 'km',
          ),
        ),
      ],
    );
  }

  Widget _interestsPage({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeading(
          'What interests you most?',
          'Choose one or more. Your coach will lean into these.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final category in EmissionCategory.values)
              _OptionCard(
                label: category.label,
                icon: categoryIcon(category),
                selected: _interests.contains(category),
                onTap: () {
                  setState(() {
                    if (_interests.contains(category)) {
                      _interests.remove(category);
                    } else {
                      _interests.add(category);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _habitsPage({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeading(
          'Which habits sound like you?',
          'Turn on the ones you already keep.',
        ),
        const SizedBox(height: 8),
        for (final habit in onboardingHabits)
          SwitchListTile(
            title: Text(habit.label),
            contentPadding: EdgeInsets.zero,
            value: _habits[habit.id]!,
            onChanged: (value) {
              setState(() => _habits[habit.id] = value);
            },
          ),
      ],
    );
  }

  Widget _pageHeading(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i <= current ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    i <= current ? scheme.primary : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            '$current of $total',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, t, child) {
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
            );
          },
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
        ),
        const SizedBox(height: 20),
        Text(
          'EcoAction',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Small actions add up to real change.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Text(
          'Pick a few simple habits, log them daily, and watch your '
          'estimated CO₂e savings grow — all on this device.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, t, child) {
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: t, child: child),
            );
          },
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.emoji_events, size: 46, color: scheme.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "You're all set.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "Let's build a greener tomorrow, one action at a time.",
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 140,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
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
