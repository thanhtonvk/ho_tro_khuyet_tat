import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'models/face_result.dart';

class FaceResultPainter extends CustomPainter {
  FaceResultPainter({
    required this.image,
    required this.results,
    Paint? drawRectPaint,
    TextStyle? labelTextStyle,
  }) {
    final defaultDrawRectPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = min(image.width, image.height) * 0.01;
    this.drawRectPaint = drawRectPaint ?? defaultDrawRectPaint;

    this.labelTextStyle = labelTextStyle ??
        TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: min(image.width, image.height) * 0.05,
        );
  }

  final ui.Image image;

  final List<FaceResult> results;

  late Paint drawRectPaint;

  late TextStyle labelTextStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());

    for (final e in results) {
      final rect = ui.Rect.fromLTWH(
        e.x,
        e.y,
        e.width,
        e.height,
      );
      canvas.drawRect(
        rect,
        drawRectPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
