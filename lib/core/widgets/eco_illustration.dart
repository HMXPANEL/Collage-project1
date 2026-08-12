import 'package:flutter/material.dart';

/// Large vector hero art used by onboarding.
///
/// Pure [CustomPaint] — no image assets, no network, cheap to render on
/// low/mid-range phones. Pass [color] to pin the palette on a dark branded
/// background; otherwise it adapts to the ambient [ColorScheme] so it works
/// in light and dark themes.
class EcoIllustration extends StatelessWidget {
  const EcoIllustration({
    super.key,
    this.variant = EcoIllustrationVariant.sprout,
    this.color,
    this.glow,
  });

  final EcoIllustrationVariant variant;
  final Color? color;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _IllustrationPainter(
        variant: variant,
        base: color ?? scheme.secondary,
        glow: glow ?? scheme.primary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

enum EcoIllustrationVariant { leaf, sprout }

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({
    required this.variant,
    required this.base,
    required this.glow,
  });

  final EcoIllustrationVariant variant;
  final Color base;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    // Unit space: 1.0 == half the shortest side, origin at the art centre.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.shortestSide / 2);

    canvas.drawCircle(
      Offset.zero,
      1.2,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.32), glow.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.35)),
    );

    final light = Color.lerp(base, Colors.white, 0.34)!;
    final dark = Color.lerp(base, Colors.black, 0.32)!;
    final leafFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, base, dark],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.15));
    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04
      ..strokeCap = StrokeCap.round;
    final sideVein = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022
      ..strokeCap = StrokeCap.round;

    if (variant == EcoIllustrationVariant.leaf) {
      _drawHeroLeaf(canvas, leafFill, vein, sideVein, dark);
    } else {
      _drawSprout(canvas, leafFill, vein, dark);
    }
  }

  void _drawHeroLeaf(
    Canvas canvas,
    Paint fill,
    Paint vein,
    Paint sideVein,
    Color dark,
  ) {
    // Secondary leaf behind the main one, tilted up-right for depth.
    canvas.save();
    canvas
      ..translate(0.52, -0.14)
      ..rotate(0.75)
      ..scale(0.46);
    canvas.drawPath(_leafPath(), Paint()..color = dark.withValues(alpha: 0.5));
    canvas.restore();

    canvas.save();
    canvas
      ..translate(0.0, 0.08)
      ..rotate(-0.42);
    canvas.drawPath(_leafPath(), fill);
    canvas.drawLine(const Offset(0, -0.5), const Offset(0, 0.46), vein);
    for (final y in const [-0.32, -0.06, 0.20]) {
      canvas
        ..drawLine(Offset(0, y), Offset(0.17, y + 0.09), sideVein)
        ..drawLine(Offset(0, y), Offset(-0.17, y + 0.09), sideVein);
    }
    canvas.restore();
  }

  void _drawSprout(Canvas canvas, Paint fill, Paint vein, Color dark) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0.58), width: 1.6, height: 0.36),
      Paint()..color = glow.withValues(alpha: 0.28),
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, 0.56)
        ..quadraticBezierTo(0.10, -0.05, 0, -0.32),
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.075
        ..strokeCap = StrokeCap.round,
    );

    _drawLeaf(canvas, fill, vein, const Offset(0, -0.30), -0.18, 0.72);
    _drawLeaf(canvas, fill, vein, const Offset(-0.48, 0.05), 2.3, 0.46);
    _drawLeaf(canvas, fill, vein, const Offset(0.48, -0.08), -2.35, 0.50);
  }

  void _drawLeaf(
    Canvas canvas,
    Paint fill,
    Paint vein,
    Offset at,
    double angle,
    double scale,
  ) {
    canvas.save();
    canvas
      ..translate(at.dx, at.dy)
      ..rotate(angle)
      ..scale(scale);
    canvas.drawPath(_leafPath(), fill);
    canvas.drawLine(const Offset(0, -0.5), const Offset(0, 0.44), vein);
    canvas.restore();
  }

  /// Symmetric teardrop leaf, tip at the top, spanning y in [-0.5, 0.5].
  Path _leafPath() {
    return Path()
      ..moveTo(0, -0.52)
      ..cubicTo(0.42, -0.30, 0.44, 0.14, 0.16, 0.42)
      ..cubicTo(0.09, 0.50, -0.09, 0.50, -0.16, 0.42)
      ..cubicTo(-0.44, 0.14, -0.42, -0.30, 0, -0.52)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter old) =>
      old.variant != variant || old.base != base || old.glow != glow;
}
