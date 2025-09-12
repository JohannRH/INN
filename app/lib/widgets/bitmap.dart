import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

Future<Uint8List> createMarkerBitmap({
  required Color color,
  required IconData icon,
  double size = 100,
  double iconSize = 48,
}) async {
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint()..color = color;

  // Dibuja círculo de fondo
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2,
    paint,
  );

  // Dibuja el ícono en el centro
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );

  // Convertir a PNG
  final picture = pictureRecorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
