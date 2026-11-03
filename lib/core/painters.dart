import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'theme.dart';

/// radial-gradient(circle, rgba(255,255,255,.04) 1px, transparent 1px) / 24px
class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = wh(0.04);
    for (double y = 12; y < size.height + 12; y += 24) {
      for (double x = 12; x < size.width + 12; x += 24) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `.hero-grid` — 1px lines every 80px at rgba(255,255,255,.015)
class HeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = wh(0.015);
    for (double x = 0; x < size.width; x += 80) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (double y = 0; y < size.height; y += 80) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Blueprint grid of the "wireframe" layer (24px, #0D99FF, 15 % opacity).
class BlueGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = op(C.blue, 0.15);
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Border on top + left + right only, with the two top corners rounded
/// (`rounded-t-[120px] border-t border-x`).
class TopRoundedBorderPainter extends CustomPainter {
  TopRoundedBorderPainter({required this.radius, required this.color, this.width = 1});
  final double radius;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final h = width / 2;
    final r = radius - h;
    final path = Path()
      ..moveTo(h, size.height)
      ..lineTo(h, radius)
      ..arcToPoint(Offset(radius, h), radius: Radius.circular(r))
      ..lineTo(size.width - radius, h)
      ..arcToPoint(Offset(size.width - h, radius), radius: Radius.circular(r))
      ..lineTo(size.width - h, size.height);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant TopRoundedBorderPainter old) =>
      old.radius != radius || old.color != color || old.width != width;
}

/// CSS `border: 1px dashed` approximation.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.left = true,
    this.dash = 3,
    this.gap = 3,
  });
  final Color color;
  final bool top, right, bottom, left;
  final double dash, gap;

  void _line(Canvas canvas, Offset a, Offset b, Paint p) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final end = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * end, p);
      d += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    if (top) _line(canvas, const Offset(0, 0.5), Offset(w, 0.5), p);
    if (bottom) _line(canvas, Offset(0, h - 0.5), Offset(w, h - 0.5), p);
    if (left) _line(canvas, const Offset(0.5, 0), Offset(0.5, h), p);
    if (right) _line(canvas, Offset(w - 0.5, 0), Offset(w - 0.5, h), p);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter old) => old.color != color;
}

/// Figma-style cursor arrow: `M1 1L1 17.5L5.5 13L9 21L11 20L7.5 12H14L1 1Z`
class CursorArrowPainter extends CustomPainter {
  CursorArrowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, 1)
      ..lineTo(1, 17.5)
      ..lineTo(5.5, 13)
      ..lineTo(9, 21)
      ..lineTo(11, 20)
      ..lineTo(7.5, 12)
      ..lineTo(14, 12)
      ..lineTo(1, 1)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.miter
        ..color = const Color(0xFF090909),
    );
  }

  @override
  bool shouldRepaint(covariant CursorArrowPainter old) => old.color != color;
}

/// Lucide `play` icon with `fill` (24 × 24 viewBox scaled to [size]).
class PlayFilledPainter extends CustomPainter {
  PlayFilledPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(6 * s, 3 * s)
      ..lineTo(20 * s, 12 * s)
      ..lineTo(6 * s, 21 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant PlayFilledPainter old) => old.color != color;
}

/// Clips a layer to the left `fraction` of its width (`clip-path: inset(0 X% 0 0)`).
class LeftFractionClipper extends CustomClipper<Rect> {
  LeftFractionClipper(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant LeftFractionClipper old) => old.fraction != fraction;
}

/// Reveals a layer from the top down (`clip-path: inset(0 0 X% 0)`).
class TopRevealClipper extends CustomClipper<Rect> {
  TopRevealClipper(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(covariant TopRevealClipper old) => old.fraction != fraction;
}

/// Film-grain noise tile painter (replaces the SVG feTurbulence overlay).
class NoisePainter extends CustomPainter {
  NoisePainter({required this.image, required this.offset});
  final ui.Image image;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.translationValues(offset.dx, offset.dy, 0).storage,
    );
    final paint = Paint()
      ..shader = shader
      ..colorFilter = const ColorFilter.mode(Color.fromRGBO(255, 255, 255, 0.035), BlendMode.modulate);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant NoisePainter old) => old.offset != offset || old.image != image;
}
