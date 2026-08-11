import 'package:flutter/material.dart';

import '../../domain/models/emission_factor.dart';

/// Icon used to represent an emission category across the app.
IconData categoryIcon(EmissionCategory category) {
  return switch (category) {
    EmissionCategory.transport => Icons.directions_bus,
    EmissionCategory.energy => Icons.lightbulb,
    EmissionCategory.waste => Icons.delete_outline,
    EmissionCategory.water => Icons.water_drop,
    EmissionCategory.food => Icons.restaurant,
    EmissionCategory.lifestyle => Icons.self_improvement,
  };
}
