import 'package:flutter/material.dart';

import 'core/router.dart';
import 'core/theme/ecoaction_theme.dart';

class EcoActionApp extends StatelessWidget {
  const EcoActionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EcoAction',
      debugShowCheckedModeBanner: false,
      theme: EcoActionTheme.light(),
      darkTheme: EcoActionTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
