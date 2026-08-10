import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/eco_card.dart';
import '../../domain/models/emission_factor.dart';
import '../../domain/models/onboarding_habits.dart';
import '../../domain/models/user_profile.dart';

const _transportOptions = [
  (label: 'Walk', value: 'walk'),
  (label: 'Cycle', value: 'cycle'),
  (label: 'Bus', value: 'bus'),
  (label: 'Scooter', value: 'scooter'),
  (label: 'Car', value: 'car'),
  (label: 'Rarely commute', value: 'none'),
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

  static const int _lastStep = 4;

  void _advance() {
    if (_step < _lastStep) {
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
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
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
      0 => const _Intro(),
      1 => _transportPage(key: const ValueKey('transport')),
      2 => _interestsPage(key: const ValueKey('interests')),
      3 => _habitsPage(key: const ValueKey('habits')),
      _ => _reviewPage(key: const ValueKey('review')),
    };
  }

  Widget _footer() {
    final isLast = _step == _lastStep;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_step == 0) const Spacer(),
        FilledButton.icon(
          onPressed: _saving ? null : _advance,
          icon: Icon(isLast ? Icons.eco : Icons.arrow_forward),
          label: Text(_saving
              ? 'Saving…'
              : isLast
                  ? 'Finish'
                  : 'Continue'),
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
        Text('How do you usually travel?', style: _titleStyle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _transportOptions)
              ChoiceChip(
                label: Text(option.label),
                selected: _transportBaseline == option.value,
                onSelected: (selected) {
                  setState(() {
                    _transportBaseline = selected ? option.value : null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Daily distance to college or work (km)', style: _titleStyle),
        const SizedBox(height: 8),
        TextField(
          controller: _commuteController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 6 (optional)',
            prefixIcon: Icon(Icons.directions_walk),
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
        Text('What interests you most?', style: _titleStyle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in EmissionCategory.values)
              FilterChip(
                label: Text(category.label),
                selected: _interests.contains(category),
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? _interests.add(category)
                        : _interests.remove(category);
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
        Text('Which habits sound like you?', style: _titleStyle),
        const SizedBox(height: 16),
        for (final habit in onboardingHabits)
          SwitchListTile(
            title: Text(habit.label),
            value: _habits[habit.id]!,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() => _habits[habit.id] = value);
            },
          ),
      ],
    );
  }

  Widget _reviewPage({Key? key}) {
    final scheme = Theme.of(context).colorScheme;
    return EcoCard(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are all set', style: _titleStyle),
            const SizedBox(height: 12),
            _reviewRow(
              'Travel',
              _transportBaseline == null
                  ? 'Not shared'
                  : _transportOptions
                      .firstWhere((o) => o.value == _transportBaseline)
                      .label,
            ),
            _reviewRow(
                'Interests',
                _interests.isEmpty
                    ? 'Not shared'
                    : '${_interests.length} selected'),
            _reviewRow(
                'Habits', '${_habits.values.where((v) => v).length} selected'),
            const SizedBox(height: 8),
            Text(
              'Everything stays on this device.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }

  TextStyle? get _titleStyle => Theme.of(context).textTheme.titleLarge;
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.eco, size: 80, color: scheme.primary),
        const SizedBox(height: 16),
        Text('EcoAction', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Small actions add up to real change. '
          'Track what you do, estimate your impact, and build greener habits.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
