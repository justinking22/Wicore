import 'package:flutter/material.dart';
import 'package:Wicore/styles/colors.dart';

class DiagonalStripesPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double spacing;
  final bool isReversed;

  DiagonalStripesPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.spacing = 6.0,
    this.isReversed = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background paint
    final bgPaint =
        Paint()
          ..color = CustomColors.limeGreen
          ..style = PaintingStyle.fill;

    // Draw background first
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Stripes paint
    final stripePaint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Draw diagonal stripes
    if (isReversed) {
      for (
        double i = -size.height;
        i < size.width + size.height;
        i += spacing
      ) {
        canvas.drawLine(
          Offset(i, size.height),
          Offset(i + size.height, 0),
          stripePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DiagonalStripesPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.spacing != spacing ||
      oldDelegate.isReversed != isReversed;
}
