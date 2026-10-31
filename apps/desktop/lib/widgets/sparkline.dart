import 'dart:math';

import 'package:flutter/material.dart';

/// Tiny trend line: monthly values, last point marked. No axes.
class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, required this.color, this.width = 96, this.height = 24});

  final List<int> values;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(painter: _SparkPainter(values, color)),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final top = values.reduce(max).toDouble(), bottom = min(0, values.reduce(min)).toDouble();
    final span = top - bottom == 0 ? 1 : top - bottom;
    Offset at(int i) =>
        Offset(i * size.width / (values.length - 1), size.height - 2 - (values[i] - bottom) / span * (size.height - 4));
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(at(values.length - 1), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}
