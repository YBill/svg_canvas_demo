import 'package:flutter/material.dart';

class MyPainter extends CustomPainter {
  List<Path> draws = [];
  List<Color> colors = [];
  double scaleFactor; // 缩放因子

  late Paint _paint;

  MyPainter(this.draws, this.colors, this.scaleFactor) {
    _paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scaleFactor);
    for (int i = 0; i < draws.length; i++) {
      Path path = draws[i];
      _paint.color = colors[i];
      canvas.drawPath(path, _paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
