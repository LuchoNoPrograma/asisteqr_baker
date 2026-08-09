import 'package:flutter/material.dart';

class InstitutionMark extends StatelessWidget {
  const InstitutionMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Unidad Educativa Baker',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: const _InstitutionMarkPainter(),
    ),
  );
}

class _InstitutionMarkPainter extends CustomPainter {
  const _InstitutionMarkPainter();

  static const navy = Color(0xFF17365F);
  static const green = Color(0xFF19704D);
  static const gold = Color(0xFFD9A928);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final paint = Paint()..isAntiAlias = true;

    paint.color = navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 512, 512),
        const Radius.circular(92),
      ),
      paint,
    );

    paint.color = Colors.white;
    canvas.drawPath(
      Path()
        ..moveTo(256, 62)
        ..lineTo(420, 132)
        ..lineTo(420, 250)
        ..cubicTo(420, 349, 358, 415, 256, 451)
        ..cubicTo(154, 415, 92, 349, 92, 250)
        ..lineTo(92, 132)
        ..close(),
      paint,
    );

    paint.color = gold;
    canvas.drawCircle(const Offset(256, 145), 25, paint);
    canvas.drawPath(
      Path()
        ..moveTo(147, 227)
        ..lineTo(256, 157)
        ..lineTo(365, 227)
        ..lineTo(365, 252)
        ..lineTo(147, 252)
        ..close(),
      paint,
    );

    paint.color = navy;
    canvas.drawRect(const Rect.fromLTWH(175, 252, 162, 113), paint);
    paint.color = Colors.white;
    for (final x in [198.0, 244.0, 290.0]) {
      canvas.drawRect(Rect.fromLTWH(x, 269, 24, 78), paint);
    }
    paint.color = green;
    canvas.drawRect(const Rect.fromLTWH(232, 291, 48, 74), paint);
    paint.color = gold;
    canvas.drawRect(const Rect.fromLTWH(146, 365, 220, 24), paint);

    paint.color = green;
    canvas.drawPath(
      Path()
        ..moveTo(120, 405)
        ..cubicTo(167, 386, 211, 385, 252, 403)
        ..lineTo(252, 437)
        ..cubicTo(207, 417, 165, 418, 120, 434)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(260, 403)
        ..cubicTo(301, 385, 345, 386, 392, 405)
        ..lineTo(392, 434)
        ..cubicTo(347, 418, 305, 417, 260, 437)
        ..close(),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
