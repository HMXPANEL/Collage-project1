import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/state/providers.dart';
import 'core/theme/ecoaction_theme.dart';

class EcoActionApp extends ConsumerWidget {
  const EcoActionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EcoAction',
      debugShowCheckedModeBanner: false,
      theme: EcoActionTheme.light(),
      darkTheme: EcoActionTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
