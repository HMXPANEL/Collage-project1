import 'package:flutter/material.dart';

import '../precision/formatting.dart';

/// Compact chip that renders an estimated impact value, e.g. "~0.42 kg CO₂e".
class EstimateChip extends StatelessWidget {
  const EstimateChip({super.key, required this.estimateInKg});

  final double estimateInKg;

  @override
  Widget build(BuildContext context) {
    final label = '~${Formatting.compactKg(estimateInKg)}';
    return Chip(
      avatar: const Icon(Icons.eco_outlined, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
