import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon_screen.dart';
import '../../core/widgets/eco_icons.dart';

class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  static const _message = 'Impact history and charts arrive in Phase 7.';

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'My Impact',
      icon: EcoIcons.impact,
      message: _message,
    );
  }
}
