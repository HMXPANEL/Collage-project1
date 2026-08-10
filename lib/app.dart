import 'package:flutter/material.dart';

import 'core/theme/ecoaction_theme.dart';
import 'features/bootstrap/bootstrap_screen.dart';

class EcoActionApp extends StatelessWidget {
  const EcoActionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoAction',
      debugShowCheckedModeBanner: false,
      theme: EcoActionTheme.light(),
      darkTheme: EcoActionTheme.dark(),
      home: const BootstrapScreen(),
    );
  }
}