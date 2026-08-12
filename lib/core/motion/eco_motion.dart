import 'package:flutter/material.dart';

/// Central motion tokens so every animation shares the same durations,
/// easing curves and reduced-motion behaviour instead of arbitrary values.
///
/// Keep durations short (180–350ms), ease naturally, and never block the
/// user — animation is feedback, not a gate.
abstract final class EcoMotion {
  /// Fast feedback: presses, selection, small state changes.
  static const Duration fast = Duration(milliseconds: 180);

  /// Standard state transitions: cards, chips, toggles.
  static const Duration base = Duration(milliseconds: 250);

  /// Slower reveals: numbers, progress, chart growth.
  static const Duration slow = Duration(milliseconds: 350);

  /// Full-screen and card entrance.
  static const Duration entrance = Duration(milliseconds: 450);

  /// Entry easing: quick start, soft landing, no bounce.
  static const Curve enter = Curves.easeOutCubic;

  /// Gentle state easing for selection and value changes.
  static const Curve state = Curves.easeOutCubic;

  /// Entrance duration, or [Duration.zero] when the platform asks for
  /// reduced motion so users get instant, static content.
  static Duration entranceFor(BuildContext context) =>
      reduced(context) ? Duration.zero : entrance;

  /// True when the OS/accessibility requests reduced motion or no animation.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
