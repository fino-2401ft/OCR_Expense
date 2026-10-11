import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../expenses/models/expense_category.dart';

class DonutSlice {
  DonutSlice({required this.category, required this.amount});
  final ExpenseCategory category;
  final int amount;
}

class DonutChartPainter extends CustomPainter {
  DonutChartPainter({required this.slices});

  final List<DonutSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = slices.fold<int>(0, (s, e) => s + e.amount);

    if (total <= 0) {
      final paint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.28;
      canvas.drawCircle(center, radius * 0.72, paint);
      return;
    }

    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.amount <= 0) continue;
      final sweep = (slice.amount / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.28
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(radius * 0.14), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
