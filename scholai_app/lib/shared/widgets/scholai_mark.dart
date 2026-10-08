import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Reusable vector-rendered ScholAI brand mark ("The Sculptural Ember Ribbon").
/// Features smooth gradients, optional gentle glow, and customizable scale.
class ScholAIMark extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showGlow;

  const ScholAIMark({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget mark = CustomPaint(
      size: Size(size, size),
      painter: _ScholAIMarkPainter(hasGlow: showGlow),
    );

    if (showGlow) {
      mark = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: size * 0.4,
              spreadRadius: 2,
            ),
          ],
        ),
        child: mark,
      );
    }

    if (!showWordmark) return mark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.2),
        Text(
          'ScholAI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ScholAIMarkPainter extends CustomPainter {
  final bool hasGlow;
  _ScholAIMarkPainter({required this.hasGlow});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 512.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Terracotta ribbon gradient
    final ribbonGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFD4845A),
        Color(0xFFB85C38),
        Color(0xFF8C3D20),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(const Rect.fromLTWH(120, 60, 280, 440));

    // Inner ember gradient
    final emberGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE59866),
        Color(0xFFB85C38),
      ],
    ).createShader(const Rect.fromLTWH(230, 140, 50, 100));

    final ribbonPaint = Paint()
      ..shader = ribbonGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final emberPaint = Paint()
      ..shader = emberGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Inner Ember
    final emberPath = Path()
      ..moveTo(256, 142)
      ..cubicTo(256, 142, 278, 182, 278, 206)
      ..cubicTo(278, 224, 268, 238, 256, 238)
      ..cubicTo(244, 238, 234, 224, 234, 206)
      ..cubicTo(234, 182, 256, 142, 256, 142)
      ..close();
    canvas.drawPath(emberPath, emberPaint);

    // Upper Ribbon Accent
    final upperAccentPath = Path()
      ..moveTo(256, 70)
      ..cubicTo(286, 110, 326, 156, 326, 206)
      ..cubicTo(326, 216, 322, 226, 314, 234)
      ..cubicTo(304, 214, 290, 196, 270, 178)
      ..cubicTo(258, 132, 256, 70, 256, 70)
      ..close();
    canvas.drawPath(upperAccentPath, ribbonPaint..color = ribbonPaint.color.withValues(alpha: 0.9));

    // Main Sweeping S-Curve Body
    final mainBodyPath = Path()
      ..moveTo(256, 70)
      ..cubicTo(220, 120, 188, 180, 188, 232)
      ..cubicTo(188, 286, 230, 316, 274, 340)
      ..cubicTo(316, 364, 332, 388, 332, 414)
      ..cubicTo(332, 444, 306, 462, 268, 462)
      ..cubicTo(222, 462, 188, 434, 188, 398)
      ..lineTo(142, 398)
      ..cubicTo(142, 462, 194, 506, 268, 506)
      ..cubicTo(336, 506, 380, 464, 380, 408)
      ..cubicTo(380, 360, 346, 328, 298, 300)
      ..cubicTo(256, 276, 234, 256, 234, 226)
      ..cubicTo(234, 196, 256, 148, 280, 114)
      ..cubicTo(268, 98, 256, 70, 256, 70)
      ..close();
    canvas.drawPath(mainBodyPath, ribbonPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
