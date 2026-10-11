import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  CropOverlayPainter({required this.cropRect});

  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final clear = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(cropRect, const Radius.circular(12)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(clear, overlay);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cropRect, const Radius.circular(12)),
      border,
    );

    final corner = Paint()
      ..color = const Color(0xFF3DDC97)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 22.0;
    // Top-left
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(len, 0), corner);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, len), corner);
    // Top-right
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-len, 0), corner);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, len), corner);
    // Bottom-left
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(len, 0), corner);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -len), corner);
    // Bottom-right
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-len, 0), corner);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -len), corner);
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}
