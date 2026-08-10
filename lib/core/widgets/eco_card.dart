import 'package:flutter/material.dart';

/// Rounded, theme-styled surface used across the app.
///
/// Style comes from [ThemeData.cardTheme]; this widget only removes the
/// default margin so callers stay in control of their layout.
class EcoCard extends StatelessWidget {
  const EcoCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(margin: EdgeInsets.zero, elevation: 0, child: child);
  }
}
