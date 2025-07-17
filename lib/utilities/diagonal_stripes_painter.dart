import 'package:Wicore/styles/colors.dart';
import 'package:flutter/material.dart';

class DiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = CustomColors.neonYellow
          ..strokeWidth = 2;

    // Draw diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += 4) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
