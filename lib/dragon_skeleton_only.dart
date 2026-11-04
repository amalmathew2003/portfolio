import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Wrap any page with this widget and a dragon skeleton follows the mouse.
/// Usage: DragonSkeletonCursor(child: YourPortfolioPage())
class DragonSkeletonCursor extends StatefulWidget {
  final Widget child;
  final int segments;
  final double spacing;

  /// Overall dragon size. 1.0 = original size, 0.75 = a little smaller.
  final double scale;

  const DragonSkeletonCursor({
    super.key,
    required this.child,
    this.segments = 38,
    this.spacing = 13,
    this.scale = 0.75,
  });

  @override
  State<DragonSkeletonCursor> createState() => _DragonSkeletonCursorState();
}

class _DragonSkeletonCursorState extends State<DragonSkeletonCursor>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<Offset> _points;
  final ValueNotifier<double> _repaint = ValueNotifier(0);

  Offset _target = const Offset(300, 300);
  bool _hasPointer = false;
  double _time = 0;
  double _phase = 0; // walking cycle, grows as the dragon moves

  @override
  void initState() {
    super.initState();
    _points = List.generate(
      widget.segments,
      (i) => Offset(300 - i * widget.spacing, 300),
    );
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _time = elapsed.inMicroseconds / 1e6;

    if (!_hasPointer) {
      final size = MediaQuery.of(context).size / widget.scale;
      _target = Offset(
        size.width / 2 + math.cos(_time * 0.8) * size.width * 0.3,
        size.height / 2 + math.sin(_time * 1.2) * size.height * 0.25,
      );
    }

    final prevHead = _points[0];
    _points[0] = Offset.lerp(_points[0], _target, 0.12)!;
    _phase += (_points[0] - prevHead).distance * 0.09;

    for (int i = 1; i < _points.length; i++) {
      final dir = _points[i - 1] - _points[i];
      final dist = dir.distance;
      if (dist > 0.001) {
        _points[i] = _points[i - 1] - dir / dist * widget.spacing;
      }
    }

    _repaint.value = _time;
  }

  void _updateTarget(PointerEvent e) {
    _hasPointer = true;
    _target = e.localPosition / widget.scale;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: _updateTarget,
      onPointerMove: _updateTarget,
      onPointerDown: _updateTarget,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _DragonPainter(
                    points: _points,
                    repaint: _repaint,
                    timeOf: () => _time,
                    phaseOf: () => _phase,
                    scale: widget.scale,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragonPainter extends CustomPainter {
  final List<Offset> points;
  final double Function() timeOf;
  final double Function() phaseOf;
  final double scale;

  _DragonPainter({
    required this.points,
    required this.timeOf,
    required this.phaseOf,
    required this.scale,
    required Listenable repaint,
  }) : super(repaint: repaint);

  static const Color bone = Color(0xFFE9E2CF);
  static const Color boneDark = Color(0xFF8E8672);
  static const Color glow = Color(0xFFFF3B30);

  double _heading(int i) {
    if (i == 0) {
      final d = points[0] - points[1];
      return math.atan2(d.dy, d.dx);
    }
    final d = points[i - 1] - points[i];
    return math.atan2(d.dy, d.dx);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = timeOf();
    final phase = phaseOf();
    final n = points.length;

    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = bone
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = bone
      ..style = PaintingStyle.fill;

    // Wings
    _drawWing(canvas, 5, -1, t);
    _drawWing(canvas, 5, 1, t);

    // Front arms with hands (shoulders) and hind legs (hips)
    for (final s in [-1.0, 1.0]) {
      _drawLimb(canvas, 10, s, phase, hind: false, scale: 0.95);
      _drawLimb(canvas, 21, s, phase, hind: true, scale: 1.1);
    }

    // Spine line
    final spine = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < n; i++) {
      spine.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      spine,
      Paint()
        ..color = boneDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Ribs + vertebrae
    for (int i = n - 1; i >= 1; i--) {
      final p = points[i];
      final a = _heading(i);
      final k = i / n;
      final taper = math.pow(1 - k, 0.75).toDouble();

      canvas.drawCircle(p, 1.6 + 3.4 * taper, fill);

      if (i > 2 && i < n * 0.72) {
        final ribLen = 4 + 24 * taper;
        final nx = -math.sin(a);
        final ny = math.cos(a);
        final tx = math.cos(a);
        final ty = math.sin(a);

        stroke.strokeWidth = 1.2 + 1.6 * taper;

        for (final s in [-1.0, 1.0]) {
          final end = p +
              Offset(nx * s * ribLen, ny * s * ribLen) -
              Offset(tx, ty) * (ribLen * 0.45);
          final ctrl = p +
              Offset(nx * s * ribLen * 0.9, ny * s * ribLen * 0.9) +
              Offset(tx, ty) * (ribLen * 0.15);
          final rib = Path()
            ..moveTo(p.dx, p.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
          canvas.drawPath(rib, stroke);
        }
      }

      if (i >= n * 0.72 && i % 2 == 0) {
        final nx = -math.sin(a);
        final ny = math.cos(a);
        stroke.strokeWidth = 1.2;
        for (final s in [-1.0, 1.0]) {
          canvas.drawLine(
            p,
            p +
                Offset(nx * s * 5, ny * s * 5) -
                Offset(math.cos(a), math.sin(a)) * 3,
            stroke,
          );
        }
      }
    }

    // Head
    _drawHead(canvas, t);

    canvas.restore();
  }

  void _drawWing(Canvas canvas, int idx, double side, double t) {
    final anchor = points[idx];
    final base = _heading(idx);
    final flap = math.sin(t * 3.2) * 0.28;

    final armAngle = base + side * (math.pi * 0.62 + flap);
    final armDir = Offset(math.cos(armAngle), math.sin(armAngle));
    final elbow = anchor + armDir * 52;

    final fingerAngles = [-0.55, -0.05, 0.45];
    final fingerLens = [78.0, 92.0, 68.0];
    final tips = <Offset>[];

    for (int f = 0; f < 3; f++) {
      final ang = armAngle + side * fingerAngles[f] + side * flap * 0.6;
      tips.add(elbow + Offset(math.cos(ang), math.sin(ang)) * fingerLens[f]);
    }

    final membrane = Path()..moveTo(anchor.dx, anchor.dy);
    membrane.lineTo(elbow.dx, elbow.dy);
    for (final tip in tips) {
      membrane.lineTo(tip.dx, tip.dy);
    }
    final back = points[math.min(idx + 5, points.length - 1)];
    membrane.lineTo(back.dx, back.dy);
    membrane.close();

    canvas.drawPath(membrane, Paint()..color = glow.withAlpha(22));
    canvas.drawPath(
      membrane,
      Paint()
        ..color = bone.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final bonePaint = Paint()
      ..color = bone
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;

    canvas.drawLine(anchor, elbow, bonePaint);
    bonePaint.strokeWidth = 1.8;
    for (final tip in tips) {
      canvas.drawLine(elbow, tip, bonePaint);
    }
    canvas.drawCircle(elbow, 3, Paint()..color = bone);
  }

  void _drawLimb(
    Canvas canvas,
    int idx,
    double side,
    double phase, {
    required bool hind,
    double scale = 1,
  }) {
    final anchor = points[idx];
    final a = _heading(idx);

    // Opposite sides and front/back pairs swing in opposite directions
    final swing = math.sin(
          phase + (side > 0 ? 0 : math.pi) + (hind ? math.pi : 0),
        ) *
        0.5;

    final upperAngle = a + side * (math.pi / 2 - swing);
    final upperLen = (hind ? 30.0 : 26.0) * scale;
    final lowerLen = (hind ? 34.0 : 28.0) * scale;

    final joint =
        anchor + Offset(math.cos(upperAngle), math.sin(upperAngle)) * upperLen;

    // Elbow bends forward, knee bends backward
    final bend = hind ? 0.7 : -0.6;
    final lowerAngle = upperAngle + side * bend + side * swing * 0.4;
    final wrist =
        joint + Offset(math.cos(lowerAngle), math.sin(lowerAngle)) * lowerLen;

    final bonePaint = Paint()
      ..color = bone
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Upper and lower bones
    canvas.drawLine(anchor, joint, bonePaint..strokeWidth = 3.2);
    canvas.drawLine(joint, wrist, bonePaint..strokeWidth = 2.4);

    // Joints
    final fill = Paint()..color = bone;
    canvas.drawCircle(anchor, 4.5, fill);
    canvas.drawCircle(joint, 3.2, fill);
    canvas.drawCircle(wrist, 2.6, fill);

    // Hand / foot with 4 fingers and curved claws
    final fingerPaint = Paint()
      ..color = bone
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    final clawPaint = Paint()
      ..color = bone
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    for (int k = 0; k < 4; k++) {
      final ang = lowerAngle + (k - 1.5) * 0.38;
      final knuckle = wrist + Offset(math.cos(ang), math.sin(ang)) * 9;
      final clawAng = ang + side * 0.5;
      final tip = knuckle + Offset(math.cos(clawAng), math.sin(clawAng)) * 5;

      canvas.drawLine(wrist, knuckle, fingerPaint);
      canvas.drawLine(knuckle, tip, clawPaint);
      canvas.drawCircle(knuckle, 1.3, fill);
    }
  }

  void _drawHead(Canvas canvas, double t) {
    final head = points[0];
    final a = _heading(0);

    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(a);

    final boneStroke = Paint()
      ..color = bone
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Horns
    for (final s in [-1.0, 1.0]) {
      final horn = Path()
        ..moveTo(-4, 9 * s)
        ..quadraticBezierTo(-18, 20 * s, -36, 13 * s);
      canvas.drawPath(horn, boneStroke..strokeWidth = 3);
    }

    // Skull
    final skull = Path()
      ..moveTo(-12, 0)
      ..cubicTo(-12, -13, 8, -13, 24, -5)
      ..lineTo(34, -3)
      ..lineTo(34, 3)
      ..lineTo(24, 5)
      ..cubicTo(8, 13, -12, 13, -12, 0)
      ..close();

    canvas.drawPath(skull, Paint()..color = const Color(0xFF14141C));
    canvas.drawPath(skull, boneStroke..strokeWidth = 2);

    // Mouth + teeth
    final mouthOpen = (math.sin(t * 2.5) * 0.5 + 0.5) * 1.5;
    canvas.drawLine(
      const Offset(6, 0),
      const Offset(34, 0),
      Paint()
        ..color = bone
        ..strokeWidth = 1.2,
    );
    final tooth = Paint()
      ..color = bone
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (double x = 14; x <= 32; x += 4) {
      final y = 3.2 - (x - 14) * 0.08;
      canvas.drawLine(Offset(x, y), Offset(x + 0.6, y + 2.5 + mouthOpen), tooth);
      canvas.drawLine(Offset(x, -y), Offset(x + 0.6, -y - 2.5 - mouthOpen), tooth);
    }

    // Eyes + nostrils
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(4, 6 * s), 4, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(4, 6 * s),
        3.4,
        Paint()
          ..color = glow.withAlpha(160)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(4.5, 6 * s), 1.6, Paint()..color = glow);
      canvas.drawCircle(Offset(29, 1.6 * s), 0.9, Paint()..color = Colors.black);
    }

    // Brow ridge
    canvas.drawLine(const Offset(-2, -9), const Offset(12, -8), boneStroke..strokeWidth = 1.4);
    canvas.drawLine(const Offset(-2, 9), const Offset(12, 8), boneStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DragonPainter oldDelegate) => true;
}