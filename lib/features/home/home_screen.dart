import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _message = "Dashboard and today's actions arrive in Phase 5.";

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'EcoAction',
      icon: Icons.eco,
      message: _message,
    );
  }
}
