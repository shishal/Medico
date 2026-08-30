import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/comic_colors.dart';

/// Full-page “sticker sheet”: warm paper, pastel washes, notebook dots,
/// and faint medical doodles so screens match the year/mascot art.
class ComicPaperBackground extends StatelessWidget {
  const ComicPaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final comic = ComicColors.of(context);
    final brightness = Theme.of(context).brightness;

    // [isComplex] + [willChange]: false lets Flutter cache this static
    // decoration so scrolling the ListView on top stays cheap.
    return ColoredBox(
      color: comic.paper,
      child: CustomPaint(
        painter: _ComicPaperPainter(ink: comic.ink, brightness: brightness),
        isComplex: true,
        willChange: false,
        child: child,
      ),
    );
  }
}

class _ComicPaperPainter extends CustomPainter {
  const _ComicPaperPainter({required this.ink, required this.brightness});

  final Color ink;
  final Brightness brightness;

  bool get _dark => brightness == Brightness.dark;

  @override
  void paint(Canvas canvas, Size size) {
    _paintWashes(canvas, size);
    _paintDotGrid(canvas, size);
    _paintDoodles(canvas, size);
  }

  void _paintWashes(Canvas canvas, Size size) {
    final washes = _dark
        ? const [
            (0.18, 0.06, 0.42, Color(0xFF2A5A55)),
            (0.92, 0.16, 0.38, Color(0xFF6B4A28)),
            (0.08, 0.52, 0.40, Color(0xFF4A3D6B)),
            (0.88, 0.72, 0.44, Color(0xFF6B3A3A)),
            (0.48, 0.96, 0.36, Color(0xFF2A4A6B)),
            (0.62, 0.40, 0.28, Color(0xFF5A4A1C)),
          ]
        : const [
            (0.16, 0.04, 0.46, StickerFills.mint),
            (0.94, 0.14, 0.40, StickerFills.peach),
            (0.06, 0.48, 0.42, StickerFills.lavender),
            (0.90, 0.70, 0.44, StickerFills.blush),
            (0.50, 0.98, 0.38, StickerFills.sky),
            (0.64, 0.38, 0.30, StickerFills.butter),
          ];

    final alpha = _dark ? 0.42 : 0.50;
    for (final (fx, fy, radiusFrac, color) in washes) {
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(size.shortestSide * 0.08, 28),
        );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * fx, size.height * fy),
          width: size.shortestSide * radiusFrac * 2.1,
          height: size.shortestSide * radiusFrac * 1.55,
        ),
        paint,
      );
    }
  }

  void _paintDotGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: _dark ? 0.07 : 0.055)
      ..style = PaintingStyle.fill;
    const step = 22.0;
    const r = 1.05;
    for (var y = step; y < size.height; y += step) {
      for (var x = step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  void _paintDoodles(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = ink.withValues(alpha: _dark ? 0.14 : 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _stethoscope(
      canvas,
      Offset(size.width * 0.84, size.height * 0.13),
      78,
      stroke,
    );
    _flask(canvas, Offset(size.width * 0.10, size.height * 0.34), 56, stroke);
    _heart(canvas, Offset(size.width * 0.90, size.height * 0.48), 48, stroke);
    _pills(canvas, Offset(size.width * 0.12, size.height * 0.72), 52, stroke);
    _cross(canvas, Offset(size.width * 0.78, size.height * 0.82), 36, stroke);
    _bone(canvas, Offset(size.width * 0.48, size.height * 0.58), 44, stroke);
  }

  void _stethoscope(Canvas canvas, Offset c, double s, Paint stroke) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.18);
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s * 0.62),
      3.4,
      2.5,
      false,
      stroke,
    );
    canvas.drawCircle(Offset(s * 0.22, s * 0.28), s * 0.12, stroke);
    canvas.restore();
  }

  void _flask(Canvas canvas, Offset c, double s, Paint stroke) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.22);
    final path = Path()
      ..moveTo(-s * 0.12, -s * 0.36)
      ..lineTo(s * 0.12, -s * 0.36)
      ..lineTo(s * 0.12, -s * 0.04)
      ..lineTo(s * 0.28, s * 0.32)
      ..lineTo(-s * 0.28, s * 0.32)
      ..lineTo(-s * 0.12, -s * 0.04)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.restore();
  }

  void _heart(Canvas canvas, Offset c, double s, Paint stroke) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.35);
    final path = Path()
      ..moveTo(0, s * 0.32)
      ..cubicTo(-s * 0.48, 0, -s * 0.2, -s * 0.4, 0, -s * 0.08)
      ..cubicTo(s * 0.2, -s * 0.4, s * 0.48, 0, 0, s * 0.32);
    canvas.drawPath(path, stroke);
    canvas.restore();
  }

  void _pills(Canvas canvas, Offset c, double s, Paint stroke) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.12, 0),
          width: s * 0.28,
          height: s * 0.52,
        ),
        Radius.circular(s * 0.14),
      ),
      stroke,
    );
    canvas.drawCircle(Offset(s * 0.2, s * 0.04), s * 0.16, stroke);
    canvas.restore();
  }

  void _cross(Canvas canvas, Offset c, double s, Paint stroke) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 0.32, height: s),
        Radius.circular(s * 0.08),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.32),
        Radius.circular(s * 0.08),
      ),
      stroke,
    );
    canvas.restore();
  }

  void _bone(Canvas canvas, Offset c, double s, Paint stroke) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.5);
    canvas.drawLine(Offset(-s * 0.28, 0), Offset(s * 0.28, 0), stroke);
    canvas.drawCircle(Offset(-s * 0.32, -s * 0.1), s * 0.1, stroke);
    canvas.drawCircle(Offset(-s * 0.32, s * 0.1), s * 0.1, stroke);
    canvas.drawCircle(Offset(s * 0.32, -s * 0.1), s * 0.1, stroke);
    canvas.drawCircle(Offset(s * 0.32, s * 0.1), s * 0.1, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ComicPaperPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.brightness != brightness;
}
