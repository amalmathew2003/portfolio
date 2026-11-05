import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// What the dragon does when the mouse is NOT near it.
enum DragonRoam {
  /// Flies freely across the whole screen (and across all pages).
  fullScreen,

  /// Wanders only around the spot where it is now.
  nearby,

  /// Stays still until the mouse comes near.
  off,
}

/// Wrap any page with this widget and a glowing dragon skeleton follows the mouse.
///
/// Usage:
/// DragonSkeletonCursor(child: YourPortfolioPage())
///
/// Optional:
/// DragonSkeletonCursor(
///   scale: 0.75,                          // size
///   glowColor: Color(0xFFFF5A1F),         // fire orange (try cyan 0xFF18E0FF)
///   boneColor: Color(0xFFEFE8D6),
///   showEmbers: true,
///   child: YourPortfolioPage(),
/// )
class DragonSkeletonCursor extends StatefulWidget {
  final Widget child;
  final int segments;
  final double spacing;
  final double scale;
  final Color boneColor;
  final Color glowColor;
  final bool showEmbers;

  /// Real blur glow looks nicer but is heavy. Keep false for smooth speed.
  final bool softGlow;

  /// The dragon follows the mouse only when the mouse is closer than this
  /// (in screen pixels). Use double.infinity to always follow.
  final double followRadius;

  /// The dragon lets go of the mouse after it stops moving for this many
  /// seconds. Use double.infinity to never let go.
  final double followHoldSeconds;

  /// What the dragon does when the mouse is not near.
  final DragonRoam roam;

  /// For DragonRoam.nearby: how far it wanders from its spot (screen pixels).
  final double nearbyRadius;

  /// Flying speed while roaming (higher = faster).
  final double roamSpeed;

  const DragonSkeletonCursor({
    super.key,
    required this.child,
    this.segments = 32,
    this.spacing = 14,
    this.scale = 0.75,
    this.boneColor = const Color(0xFFEFE8D6),
    this.glowColor = const Color(0xFFFF5A1F),
    this.showEmbers = true,
    this.softGlow = false,
    this.followRadius = 240,
    this.followHoldSeconds = 3,
    this.roam = DragonRoam.fullScreen,
    this.nearbyRadius = 260,
    this.roamSpeed = 2.6,
  });

  @override
  State<DragonSkeletonCursor> createState() => _DragonSkeletonCursorState();
}

class _Ember {
  Offset pos;
  Offset vel;
  double life; // 1 -> 0
  final double size;
  _Ember(this.pos, this.vel, this.life, this.size);
}

class _DragonSkeletonCursorState extends State<DragonSkeletonCursor>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<Offset> _points;
  final List<_Ember> _embers = [];
  final ValueNotifier<double> _repaint = ValueNotifier(0);
  final math.Random _rng = math.Random();

  // mouse (in dragon space = screen pixels / scale)
  Offset _mouse = const Offset(300, 300);
  bool _hasPointer = false;
  double _lastMove = -999;
  bool _following = false;

  // roaming
  Offset _waypoint = const Offset(500, 300);
  Offset _home = const Offset(400, 300);
  double _nextWaypointAt = 0;
  double _roamAngle = 0;
  Size _cachedSize = const Size(800, 600); // screen size / scale

  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  double _phase = 0; // walking cycle, grows as the dragon moves
  double _speed = 0; // smoothed head speed

  @override
  void initState() {
    super.initState();
    _points = List.generate(
      widget.segments,
      (i) => Offset(300 - i * widget.spacing, 300),
    );
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // updated on resize / rotation only, not every frame
    _cachedSize = MediaQuery.sizeOf(context) / widget.scale;
    _home = Offset(_cachedSize.width / 2, _cachedSize.height / 2);
  }

  Offset _jitter(double r) => Offset(
        (_rng.nextDouble() - 0.5) * 2 * r,
        (_rng.nextDouble() - 0.5) * 2 * r,
      );

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 16667.0)
        .clamp(0.0, 3.0)
        .toDouble();
    _lastElapsed = elapsed;
    _time = elapsed.inMicroseconds / 1e6;

    // Follow the mouse only when it is near the dragon and still moving.
    final mouseActive =
        _hasPointer && (_time - _lastMove) < widget.followHoldSeconds;
    final dist = (_mouse - _points[0]).distance * widget.scale;
    if (!_following) {
      if (mouseActive && dist < widget.followRadius) _following = true;
    } else if (!mouseActive || dist > widget.followRadius * 1.5) {
      // lost the mouse: go back to roaming from where we are
      _following = false;
      _home = _points[0];
      _pickWaypoint();
    }

    final prevHead = _points[0];
    if (_following) {
      final f = 1 - math.pow(1 - 0.12, dt).toDouble();
      _points[0] = Offset.lerp(_points[0], _mouse, f)!;
    } else if (widget.roam != DragonRoam.off) {
      _roam(dt);
    }
    final delta = _points[0] - prevHead;
    final moved = delta.distance;
    if (moved > 0.5) _roamAngle = math.atan2(delta.dy, delta.dx);
    _phase += moved * 0.09;
    _speed = _speed * 0.85 + moved * 0.15;

    for (int i = 1; i < _points.length; i++) {
      final dir = _points[i - 1] - _points[i];
      final dist = dir.distance;
      if (dist > 0.001) {
        _points[i] = _points[i - 1] - dir / dist * widget.spacing;
      }
    }

    if (widget.showEmbers) _updateEmbers();

    _repaint.value = _time;
  }

  void _updateEmbers() {
    final n = _points.length;

    // tail embers
    if (_speed > 0.8 && _rng.nextDouble() < 0.55) {
      _embers.add(_Ember(
        _points[n - 1] + _jitter(4),
        _jitter(0.6),
        1,
        1.2 + _rng.nextDouble() * 1.8,
      ));
    }

    // body sparks
    if (_speed > 1.5 && _rng.nextDouble() < 0.35) {
      final i = 4 + _rng.nextInt(n - 8);
      _embers.add(_Ember(
        _points[i] + _jitter(8),
        _jitter(0.8),
        1,
        1.0 + _rng.nextDouble() * 1.5,
      ));
    }

    // mouth sparks
    if (_speed > 3 && _rng.nextDouble() < 0.6) {
      final d = _points[0] - _points[1];
      final dist = d.distance;
      if (dist > 0.001) {
        final dir = d / dist;
        _embers.add(_Ember(
          _points[0] + dir * 36,
          dir * (1.5 + _rng.nextDouble() * 2) + _jitter(0.8),
          1,
          1.5 + _rng.nextDouble() * 1.8,
        ));
      }
    }

    for (final e in _embers) {
      e.pos += e.vel;
      e.vel = e.vel * 0.96 + _jitter(0.08);
      e.life -= 0.022;
    }
    _embers.removeWhere((e) => e.life <= 0);
    if (_embers.length > 80) {
      _embers.removeRange(0, _embers.length - 80);
    }
  }

  void _updateTarget(PointerEvent e) {
    _hasPointer = true;
    _mouse = e.localPosition / widget.scale;
    _lastMove = _time;
  }

  void _pickWaypoint() {
    final s = _cachedSize;
    const m = 90.0;
    final maxX = math.max(m + 1, s.width - m);
    final maxY = math.max(m + 1, s.height - m);

    if (widget.roam == DragonRoam.nearby) {
      final r = widget.nearbyRadius / widget.scale;
      final ang = _rng.nextDouble() * math.pi * 2;
      final d = r * (0.4 + 0.6 * _rng.nextDouble());
      _waypoint = Offset(
        (_home.dx + math.cos(ang) * d).clamp(m, maxX).toDouble(),
        (_home.dy + math.sin(ang) * d).clamp(m, maxY).toDouble(),
      );
    } else {
      _waypoint = Offset(
        m + _rng.nextDouble() * (maxX - m),
        m + _rng.nextDouble() * (maxY - m),
      );
    }
    _nextWaypointAt = _time + 3 + _rng.nextDouble() * 4;
  }

  // Fly toward the waypoint with a limited turn rate, so it curves like a snake.
  void _roam(double dt) {
    if ((_points[0] - _waypoint).distance < 50 || _time > _nextWaypointAt) {
      _pickWaypoint();
    }
    final to = _waypoint - _points[0];
    final desired = math.atan2(to.dy, to.dx);

    var diff = desired - _roamAngle;
    while (diff > math.pi) {
      diff -= math.pi * 2;
    }
    while (diff < -math.pi) {
      diff += math.pi * 2;
    }
    final maxTurn = 0.05 * dt;
    _roamAngle += diff.clamp(-maxTurn, maxTurn).toDouble();

    final step = widget.roamSpeed * dt;
    _points[0] += Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * step;
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
                    embers: _embers,
                    repaint: _repaint,
                    timeOf: () => _time,
                    phaseOf: () => _phase,
                    speedOf: () => _speed,
                    scale: widget.scale,
                    bone: widget.boneColor,
                    glow: widget.glowColor,
                    softGlow: widget.softGlow,
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
  final List<_Ember> embers;
  final double Function() timeOf;
  final double Function() phaseOf;
  final double Function() speedOf;
  final double scale;
  final Color bone;
  final Color glow;
  final bool softGlow;

  _DragonPainter({
    required this.points,
    required this.embers,
    required this.timeOf,
    required this.phaseOf,
    required this.speedOf,
    required this.scale,
    required this.bone,
    required this.glow,
    required this.softGlow,
    required Listenable repaint,
  }) : super(repaint: repaint);

  Color get boneDark => Color.lerp(bone, Colors.black, 0.45)!;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _blur(Color c, double sigma) {
    final p = Paint()..color = c;
    if (softGlow) p.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    return p;
  }

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

    _drawEmbers(canvas);

    // Wings
    _drawWing(canvas, 5, -1, t);
    _drawWing(canvas, 5, 1, t);

    // Front arms with hands and hind legs
    for (final s in [-1.0, 1.0]) {
      _drawLimb(canvas, 10, s, phase, hind: false, scale: 0.95);
      _drawLimb(canvas, 21, s, phase, hind: true, scale: 1.1);
    }

    _drawSpine(canvas);
    _drawBody(canvas, n);
    _drawTailBlade(canvas);
    _drawHead(canvas, t);

    canvas.restore();
  }

  // ---------------------------------------------------------------- embers
  void _drawEmbers(Canvas canvas) {
    final p = Paint();
    if (softGlow) {
      p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    }
    for (final e in embers) {
      final life = e.life.clamp(0.0, 1.0).toDouble();
      final c = Color.lerp(const Color(0xFFFFD27A), glow, 1 - life)!;
      p.color = c.withAlpha((life * 255).round());
      canvas.drawCircle(e.pos, e.size * (0.4 + life * 0.6), p);
    }
  }

  // ----------------------------------------------------------------- spine
  void _drawSpine(Canvas canvas) {
    final spine = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      spine.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      spine,
      Paint()
        ..color = glow.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter =
            softGlow ? const MaskFilter.blur(BlurStyle.normal, 6) : null,
    );
    canvas.drawPath(spine, _stroke(boneDark, 2));
  }

  // ------------------------------------------------- vertebrae, ribs, spikes
  void _drawBody(Canvas canvas, int n) {
    for (int i = n - 1; i >= 1; i--) {
      final p = points[i];
      final a = _heading(i);
      final k = i / n; // 0 = head, 1 = tail
      final taper = math.pow(1 - k, 0.75).toDouble();
      final col = Color.lerp(bone, glow, math.pow(k, 1.5).toDouble() * 0.85)!;

      final nx = -math.sin(a);
      final ny = math.cos(a);
      final tx = math.cos(a);
      final ty = math.sin(a);

      // dorsal spike
      final len = 4 + 9 * taper;
      final spike = Path()
        ..moveTo(p.dx + tx * 2.5, p.dy + ty * 2.5)
        ..lineTo(p.dx + nx * 1.8, p.dy + ny * 1.8)
        ..lineTo(p.dx - tx * len, p.dy - ty * len)
        ..lineTo(p.dx - nx * 1.8, p.dy - ny * 1.8)
        ..close();
      canvas.drawPath(spike, Paint()..color = glow.withAlpha(200));

      // vertebra
      canvas.drawCircle(p, 1.6 + 3.4 * taper, Paint()..color = col);

      // ribs on the torso
      if (i > 2 && i < n * 0.72) {
        final ribLen = 4 + 24 * taper;
        final ribPaint = _stroke(col, 1.2 + 1.6 * taper);

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
          canvas.drawPath(rib, ribPaint);
          canvas.drawCircle(end, 1.1, Paint()..color = glow.withAlpha(220));
        }
      }

      // side spikes on the tail
      if (i >= n * 0.72 && i % 2 == 0) {
        final sp = _stroke(col, 1.2);
        for (final s in [-1.0, 1.0]) {
          canvas.drawLine(
            p,
            p + Offset(nx * s * 5, ny * s * 5) - Offset(tx, ty) * 3,
            sp,
          );
        }
      }
    }
  }

  // ------------------------------------------------------------ tail blade
  void _drawTailBlade(Canvas canvas) {
    final p = points.last;
    final a = _heading(points.length - 1);
    final tan = Offset(math.cos(a), math.sin(a));
    final nor = Offset(-math.sin(a), math.cos(a));

    final tip = p - tan * 24;
    final l = p - tan * 7 + nor * 10;
    final r = p - tan * 7 - nor * 10;

    final blade = Path()
      ..moveTo(p.dx, p.dy)
      ..lineTo(l.dx, l.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(r.dx, r.dy)
      ..close();

    canvas.drawPath(blade, _blur(glow.withAlpha(120), 5));
    canvas.drawPath(blade, Paint()..color = glow.withAlpha(190));
    canvas.drawPath(blade, _stroke(bone.withAlpha(220), 1.2));
    canvas.drawLine(p, tip, _stroke(bone.withAlpha(200), 1));
  }

  // ----------------------------------------------------------------- wings
  Offset _scallop(Offset a, Offset b, Offset toward) {
    final mid = Offset.lerp(a, b, 0.5)!;
    return mid + (toward - mid) * 0.28;
  }

  void _drawWing(Canvas canvas, int idx, double side, double t) {
    final anchor = points[idx];
    final base = _heading(idx);
    final flap = math.sin(t * 3.2) * 0.28;

    final armAngle = base + side * (math.pi * 0.62 + flap);
    final elbow =
        anchor + Offset(math.cos(armAngle), math.sin(armAngle)) * 52;

    final fingerAngles = [-0.55, -0.05, 0.45];
    final fingerLens = [78.0, 92.0, 68.0];
    final tips = <Offset>[];
    for (int f = 0; f < 3; f++) {
      final ang = armAngle + side * fingerAngles[f] + side * flap * 0.6;
      tips.add(elbow + Offset(math.cos(ang), math.sin(ang)) * fingerLens[f]);
    }

    final back = points[math.min(idx + 5, points.length - 1)];
    final c1 = _scallop(tips[0], tips[1], elbow);
    final c2 = _scallop(tips[1], tips[2], elbow);
    final c3 = _scallop(tips[2], back, anchor);

    final membrane = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(tips[0].dx, tips[0].dy)
      ..quadraticBezierTo(c1.dx, c1.dy, tips[1].dx, tips[1].dy)
      ..quadraticBezierTo(c2.dx, c2.dy, tips[2].dx, tips[2].dy)
      ..quadraticBezierTo(c3.dx, c3.dy, back.dx, back.dy)
      ..close();

    // glowing membrane, stronger toward the edges
    canvas.drawPath(
      membrane,
      Paint()
        ..shader = ui.Gradient.linear(
          anchor,
          tips[1],
          [glow.withAlpha(20), glow.withAlpha(140)],
        ),
    );
    canvas.drawPath(
      membrane,
      Paint()
        ..color = glow.withAlpha(110)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter =
            softGlow ? const MaskFilter.blur(BlurStyle.normal, 4) : null,
    );
    canvas.drawPath(membrane, _stroke(bone.withAlpha(110), 1));

    // veins
    final vein = _stroke(bone.withAlpha(70), 0.8);
    canvas.drawLine(elbow, Offset.lerp(tips[0], tips[1], 0.5)!, vein);
    canvas.drawLine(elbow, Offset.lerp(tips[1], tips[2], 0.5)!, vein);
    canvas.drawLine(anchor, Offset.lerp(tips[2], back, 0.5)!, vein);

    // bones
    canvas.drawLine(anchor, elbow, _stroke(bone, 2.8));
    final fingerPaint = _stroke(bone, 1.8);
    for (final tip in tips) {
      canvas.drawLine(elbow, tip, fingerPaint);
      canvas.drawCircle(tip, 2.2, _blur(glow.withAlpha(230), 1.5));
    }
    canvas.drawCircle(elbow, 3, Paint()..color = bone);
    canvas.drawCircle(elbow, 1.4, Paint()..color = glow);
  }

  // ------------------------------------------------------------------ limbs
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

    final swing = math.sin(
          phase + (side > 0 ? 0 : math.pi) + (hind ? math.pi : 0),
        ) *
        0.5;

    final upperAngle = a + side * (math.pi / 2 - swing);
    final upperLen = (hind ? 30.0 : 26.0) * scale;
    final lowerLen = (hind ? 34.0 : 28.0) * scale;

    final joint =
        anchor + Offset(math.cos(upperAngle), math.sin(upperAngle)) * upperLen;

    final bend = hind ? 0.7 : -0.6;
    final lowerAngle = upperAngle + side * bend + side * swing * 0.4;
    final wrist =
        joint + Offset(math.cos(lowerAngle), math.sin(lowerAngle)) * lowerLen;

    canvas.drawLine(anchor, joint, _stroke(bone, 3.2));
    canvas.drawLine(joint, wrist, _stroke(bone, 2.4));

    final fill = Paint()..color = bone;
    final dot = Paint()..color = glow;
    canvas.drawCircle(anchor, 4.5, fill);
    canvas.drawCircle(anchor, 1.8, dot);
    canvas.drawCircle(joint, 3.2, fill);
    canvas.drawCircle(joint, 1.3, dot);
    canvas.drawCircle(wrist, 2.6, fill);

    final fingerPaint = _stroke(bone, 1.6);
    final clawPaint = _stroke(Color.lerp(bone, glow, 0.6)!, 1.4);

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

  // ------------------------------------------------------------------ head
  void _drawHead(Canvas canvas, double t) {
    final head = points[0];
    final a = _heading(0);
    final fire = ((speedOf() - 2.8) / 6).clamp(0.0, 1.0).toDouble();
    final pulse = 0.75 + 0.25 * math.sin(t * 4);

    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(a);

    // soft glow under the head (only with real blur)
    if (softGlow) {
      canvas.drawCircle(
        const Offset(10, 0),
        26,
        _blur(glow.withAlpha(40), 14),
      );
    }

    // whiskers
    final whisker = _stroke(bone.withAlpha(200), 1.2);
    for (final s in [-1.0, 1.0]) {
      final w1 = math.sin(t * 4) * 4;
      final w2 = math.sin(t * 3 + 1) * 5;
      final whiskerPath = Path()
        ..moveTo(24, 4 * s)
        ..quadraticBezierTo(38, (16 * s) + w1 * s, 14, (28 * s) + w2 * s);
      canvas.drawPath(whiskerPath, whisker);
      canvas.drawCircle(
        Offset(14, (28 * s) + w2 * s),
        1.6,
        _blur(glow.withAlpha(230), 1.5),
      );
    }

    // horns with glowing tips
    for (final s in [-1.0, 1.0]) {
      final horn = Path()
        ..moveTo(-4, 9 * s)
        ..quadraticBezierTo(-18, 20 * s, -36, 13 * s);
      canvas.drawPath(horn, _stroke(bone, 3));
      canvas.drawCircle(
        Offset(-36, 13 * s),
        2.4,
        _blur(glow.withAlpha(240), 2),
      );
    }

    // skull
    final skull = Path()
      ..moveTo(-12, 0)
      ..cubicTo(-12, -13, 8, -13, 24, -5)
      ..lineTo(34, -3)
      ..lineTo(34, 3)
      ..lineTo(24, 5)
      ..cubicTo(8, 13, -12, 13, -12, 0)
      ..close();

    canvas.drawPath(skull, Paint()..color = const Color(0xFF14141C));
    canvas.drawPath(skull, _stroke(bone, 2));

    // crest diamond
    final crest = Path()
      ..moveTo(-7, 0)
      ..lineTo(0, -3)
      ..lineTo(8, 0)
      ..lineTo(0, 3)
      ..close();
    canvas.drawPath(crest, Paint()..color = glow.withAlpha(170));

    // mouth + teeth
    final mouthOpen = (math.sin(t * 2.5) * 0.5 + 0.5) * 1.5 + fire * 3;
    canvas.drawLine(const Offset(8, 0), const Offset(34, 0), _stroke(bone, 1.2));
    final tooth = _stroke(bone, 1.5);
    for (double x = 14; x <= 32; x += 4) {
      final y = 3.2 - (x - 14) * 0.08;
      canvas.drawLine(Offset(x, y), Offset(x + 0.6, y + 2.5 + mouthOpen), tooth);
      canvas.drawLine(
          Offset(x, -y), Offset(x + 0.6, -y - 2.5 - mouthOpen), tooth);
    }

    // eyes + nostrils
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(4, 6 * s), 4.2, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(4, 6 * s),
        6.5,
        _blur(glow.withAlpha((170 * pulse).round()), 5),
      );
      canvas.drawCircle(Offset(4.5, 6 * s), 2.2, Paint()..color = glow);
      canvas.drawCircle(
        Offset(4.8, 6 * s),
        1.1,
        Paint()..color = const Color(0xFFFFF1B8),
      );
      canvas.drawCircle(Offset(29, 1.6 * s), 0.9, Paint()..color = Colors.black);
    }

    // brow ridge
    canvas.drawLine(const Offset(-2, -9), const Offset(12, -8), _stroke(bone, 1.4));
    canvas.drawLine(const Offset(-2, 9), const Offset(12, 8), _stroke(bone, 1.4));

    // fire breath when moving fast
    if (fire > 0.08) {
      for (int k = 0; k < 6; k++) {
        final flick = math.sin(t * 28 + k * 1.7);
        final x = 36.0 + k * 6.5 * (0.5 + fire);
        final r = (7 - k) * (0.5 + fire * 0.9) + flick * 0.8;
        if (r <= 0.3) continue;
        final c = Color.lerp(const Color(0xFFFFE08A), glow, k / 6)!;
        canvas.drawCircle(
          Offset(x, flick * 1.5),
          r,
          _blur(c.withAlpha(math.min(255, (210 * fire).round())), 2.5),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DragonPainter oldDelegate) => true;
}