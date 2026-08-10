import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon_screen.dart';
import '../../core/widgets/eco_icons.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _message =
      'Profile, settings and your coach arrive in later phases.';

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Profile',
      icon: EcoIcons.profile,
      message: _message,
    );
  }
}
