import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon_screen.dart';
import '../../core/widgets/eco_icons.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  static const _message = 'Challenges, streaks and badges arrive in Phase 8.';

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Challenges',
      icon: EcoIcons.challenges,
      message: _message,
    );
  }
}
