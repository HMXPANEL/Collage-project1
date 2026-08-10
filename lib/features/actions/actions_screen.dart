import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon_screen.dart';
import '../../core/widgets/eco_icons.dart';

class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  static const _message = 'The action catalog arrives in Phase 6.';

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Take Action',
      icon: EcoIcons.actions,
      message: _message,
    );
  }
}
