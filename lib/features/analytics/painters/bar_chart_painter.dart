import 'package:flutter/material.dart';

class BarChartPainter extends CustomPainter {
  BarChartPainter({
    required this.values,
    required this.labels,
    this.barColor = const Color(0xFF0F6B4C),
  });

  final List<int> values;
  final List<String> labels;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 8.0;
    const bottomPad = 24.0;
    const topPad = 12.0;
    final chartHeight = size.height - bottomPad - topPad;
    final chartWidth = size.width - leftPad * 2;
    final maxValue = values.fold<int>(0, (m, v) => v > m ? v : m);
    final n = values.length;
    if (n == 0) return;

    final slot = chartWidth / n;
    final barWidth = slot * 0.55;
    final axis = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(leftPad, size.height - bottomPad),
      Offset(size.width - leftPad, size.height - bottomPad),
      axis,
    );

    final barPaint = Paint()..color = barColor;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < n; i++) {
      final v = values[i];
      final h = maxValue == 0 ? 0.0 : (v / maxValue) * chartHeight;
      final left = leftPad + slot * i + (slot - barWidth) / 2;
      final top = size.height - bottomPad - h;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, h == 0 ? 2 : h),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rect,
        barPaint..color = h == 0 ? Colors.grey.shade300 : barColor,
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
      );
      textPainter.layout(minWidth: 0, maxWidth: slot);
      textPainter.paint(
        canvas,
        Offset(
          leftPad + slot * i + (slot - textPainter.width) / 2,
          size.height - bottomPad + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
