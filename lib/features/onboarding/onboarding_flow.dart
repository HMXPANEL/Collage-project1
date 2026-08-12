import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/eco_illustration.dart';
import '../../core/widgets/ui.dart';
import '../../domain/models/emission_factor.dart';
import '../../domain/models/onboarding_habits.dart';
import '../../domain/models/user_profile.dart';

const List<({String label, String value, IconData icon})> _transportOptions = [
  (label: 'Walk', value: 'walk', icon: Icons.directions_walk),
  (label: 'Cycle', value: 'cycle', icon: Icons.directions_bike),
  (label: 'Bus', value: 'bus', icon: Icons.directions_bus),
  (label: 'Scooter', value: 'scooter', icon: Icons.two_wheeler),
  (label: 'Car', value: 'car', icon: Icons.directions_car),
  (label: 'Rarely commute', value: 'none', icon: Icons.home_outlined),
];

/// Deep-green brand background for the Welcome and "all set" bookends.
const Color _deepTop = Color(0xFF0A2B1A);
const Color _deepBottom = Color(0xFF1B6B40);

/// Bright leaf palette that stays readable on the dark brand background.
const Color _heroLeaf = Color(0xFF8FE3B2);
const Color _welcomeInk = Color(0xFFF1FBF4);
const Color _welcomeMuted = Color(0xFFC3E6CF);

const List<String> _stepTitles = [
  'Welcome',
  'Travel',
  'Interests',
  'Habits',
  'Ready'
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
  final _pageController = PageController();
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
    _pageController.dispose();
    super.dispose();
  }

  static const int _questionCount = 4;
  static const int _completionStep = _questionCount;

  void _goTo(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _advance() {
    if (_step < _completionStep) {
      _goTo(_step + 1);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0 && !_saving) _goTo(_step - 1);
  }

  String get _travelLabel {
    for (final option in _transportOptions) {
      if (option.value == _transportBaseline) return option.label;
    }
    return 'Not set';
  }

  String get _interestsText => _interests.isEmpty
      ? 'Not set'
      : _interests.map((c) => c.label).join(' · ');

  String get _habitsText {
    final count = _habits.values.where((value) => value).length;
    return '$count selected';
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

  bool get _immersive => _step == 0 || _step == _completionStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _immersive ? _deepTop : scheme.surface,
      appBar: AppBar(
        backgroundColor: _immersive ? _deepTop : scheme.surface,
        foregroundColor: _immersive ? _welcomeInk : null,
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
                tooltip: 'Back',
              ),
        title: Text(_stepTitles[_step]),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _immersive
                ? const [_deepTop, _deepBottom]
                : [scheme.surface, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              children: [
                if (_step >= 1 && _step <= _completionStep)
                  _StepProgress(total: _questionCount, current: _step),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) => setState(() => _step = index),
                    children: [
                      const _WelcomePage(key: ValueKey('welcome')),
                      _stepPage(
                        key: const ValueKey('transport'),
                        heroFraction: 0.34,
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
                                      _transportBaseline =
                                          _transportBaseline == option.value
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
                      ),
                      _stepPage(
                        key: const ValueKey('interests'),
                        heroFraction: 0.34,
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
                      ),
                      _stepPage(
                        key: const ValueKey('habits'),
                        heroFraction: 0.3,
                        children: [
                          _pageHeading(
                            'Which habits sound like you?',
                            'Turn on the ones you already keep.',
                          ),
                          const SizedBox(height: 12),
                          for (final habit in onboardingHabits) ...[
                            SwitchListTile(
                              title: Text(habit.label),
                              value: _habits[habit.id]!,
                              onChanged: (value) {
                                setState(() => _habits[habit.id] = value);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: scheme.outlineVariant),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                      _DonePage(
                        key: const ValueKey('done'),
                        travelLabel: _travelLabel,
                        interestsText: _interestsText,
                        habitsText: _habitsText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shared layout for the three question steps: a scrolling page with the
  /// sprout illustration pinned on top, sized to the available height.
  Widget _stepPage({
    Key? key,
    required double heroFraction,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final hero = (constraints.maxHeight * heroFraction)
            .clamp(100.0, 170.0)
            .toDouble();
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: hero,
                      child: const EcoIllustration(
                        variant: EcoIllustrationVariant.sprout,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...children,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
    final button = FilledButton.icon(
      onPressed: _saving ? null : _advance,
      icon: Icon(isLast ? Icons.eco : Icons.arrow_forward),
      label: Text(label),
    );
    if (_step == 0) {
      return Entrance(
        delay: 0.6,
        child: SizedBox(width: double.infinity, child: button),
      );
    }
    return Align(alignment: Alignment.centerRight, child: button);
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

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i <= current ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    i <= current ? scheme.primary : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: scheme.outlineVariant,
                  width: i <= current ? 0 : 1,
                ),
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hero =
            (constraints.maxHeight * 0.44).clamp(130.0, 250.0).toDouble();
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) => Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(
                            scale: 0.78 + 0.22 * t, child: child),
                      ),
                      child: SizedBox(
                        height: hero,
                        width: double.infinity,
                        child: const EcoIllustration(
                          variant: EcoIllustrationVariant.leaf,
                          color: _heroLeaf,
                          glow: _heroLeaf,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Entrance(
                      delay: 0.3,
                      child: Text(
                        'EcoAction',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: _welcomeInk,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Entrance(
                      delay: 0.42,
                      child: Text(
                        'Small actions add up to real change.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _welcomeMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Entrance(
                      delay: 0.52,
                      child: Text(
                        'Build simple habits.\nSee your estimated impact grow.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _welcomeMuted.withValues(alpha: 0.85),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage({
    super.key,
    required this.travelLabel,
    required this.interestsText,
    required this.habitsText,
  });

  final String travelLabel;
  final String interestsText;
  final String habitsText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hero =
            (constraints.maxHeight * 0.38).clamp(120.0, 220.0).toDouble();
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Entrance(
                      child: SizedBox(
                        height: hero,
                        width: double.infinity,
                        child: const EcoIllustration(
                          variant: EcoIllustrationVariant.leaf,
                          color: _heroLeaf,
                          glow: _heroLeaf,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Entrance(
                      delay: 0.15,
                      child: Text(
                        "You're all set.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: _welcomeInk,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Entrance(
                      delay: 0.25,
                      child: Text(
                        'Your greener journey starts here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _welcomeMuted,
                            ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Entrance(
                      delay: 0.4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _welcomeInk.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _welcomeInk.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Column(
                          children: [
                            _summaryRow(
                              context,
                              icon: Icons.directions_walk,
                              label: 'Travel',
                              value: travelLabel,
                            ),
                            const SizedBox(height: 14),
                            _summaryRow(
                              context,
                              icon: Icons.category,
                              label: 'Focus',
                              value: interestsText,
                            ),
                            const SizedBox(height: 14),
                            _summaryRow(
                              context,
                              icon: Icons.checklist,
                              label: 'Habits',
                              value: habitsText,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _welcomeInk.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: _welcomeInk),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _welcomeMuted,
                  letterSpacing: 0.6,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _welcomeInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
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
    return AnimatedScale(
      scale: selected ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 140,
        child: Material(
          color:
              selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
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
              child: Stack(
                children: [
                  Column(
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
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
