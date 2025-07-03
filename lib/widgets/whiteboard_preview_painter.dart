// ============================================================================
// WHITEBOARD PREVIEW PAINTER
// ============================================================================

import 'package:cyan/theme/cyan_theme.dart';
import 'package:flutter/material.dart';

class WhiteboardPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw some mock shapes to make it look like a real whiteboard
    // Rectangle
    paint.color = CyanTheme.primary.withOpacity(0.6);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, size.width * 0.3,
          size.height * 0.25),
      paint,
    );

    // Circle
    paint.color = CyanTheme.secondary.withOpacity(0.6);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.width * 0.12,
      paint,
    );

    // Arrow
    paint.color = CyanTheme.warning.withOpacity(0.6);
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.35),
      paint,
    );

    // Arrow head
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.6, size.height * 0.35);
    arrowPath.lineTo(size.width * 0.55, size.height * 0.32);
    arrowPath.lineTo(size.width * 0.55, size.height * 0.38);
    arrowPath.close();
    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, paint);

    // Some connecting lines
    paint
      ..color = CyanTheme.textSecondary.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.32),
      Offset(size.width * 0.45, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.65, size.height * 0.45),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
