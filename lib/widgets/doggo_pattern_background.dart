import 'package:flutter/material.dart';

class DogGoPatternBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color patternColor;
  final double opacity;

  const DogGoPatternBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFFFFBF5),
    this.patternColor = const Color(0xFF0F9B8E),
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DogGoPatternPainter(
                patternColor: patternColor,
                opacity: opacity,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DogGoPatternPainter extends CustomPainter {
  final Color patternColor;
  final double opacity;

  const _DogGoPatternPainter({
    required this.patternColor,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pawPaint = Paint()
      ..color = patternColor.withOpacity(.18 * opacity)
      ..style = PaintingStyle.fill;

    final bonePaint = Paint()
      ..color = patternColor.withOpacity(.16 * opacity)
      ..style = PaintingStyle.fill;

    const tile = 120.0;

    for (double y = -20; y < size.height + tile; y += tile) {
      for (double x = -20; x < size.width + tile; x += tile) {
        canvas.save();
        canvas.translate(x, y);

        _drawPaw(canvas, pawPaint, const Offset(30, 30), -0.52);
        _drawBone(canvas, bonePaint, const Offset(30, 90), -0.52);
        _drawBone(canvas, bonePaint, const Offset(90, 30), -0.52);
        _drawPaw(canvas, pawPaint, const Offset(90, 90), -0.52);

        canvas.restore();
      }
    }
  }

  void _drawPaw(Canvas canvas, Paint paint, Offset center, double radians) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(radians);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 16,
        height: 19,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-9, -11),
        width: 9,
        height: 10,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-3, -15),
        width: 9,
        height: 10,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(5, -15),
        width: 9,
        height: 10,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(11, -10),
        width: 8,
        height: 9.6,
      ),
      paint,
    );

    canvas.restore();
  }

  void _drawBone(Canvas canvas, Paint paint, Offset center, double radians) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(radians);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -3.5, 26, 7),
        const Radius.circular(3),
      ),
      paint,
    );

    canvas.drawCircle(const Offset(-15, -5.5), 4.2, paint);
    canvas.drawCircle(const Offset(-15, 5.5), 4.2, paint);
    canvas.drawCircle(const Offset(15, -5.5), 4.2, paint);
    canvas.drawCircle(const Offset(15, 5.5), 4.2, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DogGoPatternPainter oldDelegate) {
    return oldDelegate.patternColor != patternColor ||
        oldDelegate.opacity != opacity;
  }
}