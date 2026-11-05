import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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

/// Visual style of the bait cursor replacing the mouse pointer.
enum DragonCursorStyle {
  /// A small glowing fire ember with a rotating thin ring and orbiting sparks.
  ember,

  /// A magical celestial orb with orbiting rings and shimmering motes.
  orb,

  /// Uses the default system pointer (no custom cursor drawn).
  system,
}

/// Internal states of the dragon attraction and catching state machine.
enum _DragonState {
  roam,
  notice,
  stalk,
  lunge,
  snap,
  recover,
}

/// Wrap any page with this widget and a glowing dragon skeleton follows the mouse
/// or hunts the glowing bait cursor.
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
///   cursorStyle: DragonCursorStyle.ember,
///   enableCatching: true,
///   attractRadius: 320,
///   lungeDistance: 90,
///   catchCooldown: 2.5,
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
  /// (in screen pixels). Used when enableCatching is false.
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

  /// Bait cursor visual style (ember, orb, or system).
  final DragonCursorStyle cursorStyle;

  /// Whether to hide the operating system cursor over the app.
  final bool hideSystemCursor;

  /// Enables the attraction and catching state machine (notice -> stalk -> lunge -> snap -> recover).
  /// When false, retains the original simple follow behavior.
  final bool enableCatching;

  /// Distance in screen pixels where the dragon notices the bait cursor.
  final double attractRadius;

  /// Distance in screen pixels where the dragon lunges at the bait cursor.
  final double lungeDistance;

  /// Seconds to ignore the mouse after snapping / catching before roaming again.
  final double catchCooldown;

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
    this.cursorStyle = DragonCursorStyle.ember,
    this.hideSystemCursor = true,
    this.enableCatching = true,
    this.attractRadius = 320,
    this.lungeDistance = 90,
    this.catchCooldown = 2.5,
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

  // Mouse positions
  Offset _rawMouse = const Offset(-999, -999); // Exact screen pixels
  Offset _mouse = const Offset(300, 300); // In dragon space (screen / scale)
  bool _hasPointer = false;
  bool _mouseInWindow = false;
  bool _isTouch = false;
  double _lastMove = -999;
  bool _following = false; // For legacy follow mode

  // State machine variables
  _DragonState _state = _DragonState.roam;
  double _stateTimer = 0.0;
  double _snapFlash = 0.0; // 1.0 -> 0.0 flash when caught
  double _catchRingRadius = 0.0; // Expands outward on snap
  double _headShake = 0.0; // Oscillates during recover

  // Roaming
  Offset _waypoint = const Offset(500, 300);
  Offset _home = const Offset(400, 300);
  double _nextWaypointAt = 0;
  double _roamAngle = 0;
  Size _cachedSize = const Size(800, 600); // Screen size / scale

  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  double _phase = 0; // Walking cycle, grows as the dragon moves
  double _speed = 0; // Smoothed head speed

  @override
  void initState() {
    super.initState();
    _isTouch = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    _points = List.generate(
      widget.segments,
      (i) => Offset(300 - i * widget.spacing, 300),
    );
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Updated on resize / rotation only, not every frame
    _cachedSize = MediaQuery.sizeOf(context) / widget.scale;
    _home = Offset(_cachedSize.width / 2, _cachedSize.height / 2);
  }

  Offset _jitter(double r) => Offset(
        (_rng.nextDouble() - 0.5) * 2 * r,
        (_rng.nextDouble() - 0.5) * 2 * r,
      );

  void _onTick(Duration elapsed) {
    final dtSeconds = _lastElapsed == Duration.zero
        ? 0.016
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    final dt = (dtSeconds / 0.016667).clamp(0.0, 3.0);
    _lastElapsed = elapsed;
    _time = elapsed.inMicroseconds / 1e6;

    // Follow / attract only when pointer is active and moving inside window
    final mouseActive = _hasPointer &&
        _mouseInWindow &&
        !_isTouch &&
        (_time - _lastMove) < widget.followHoldSeconds;

    final dist = (_mouse - _points[0]).distance * widget.scale;
    final prevHead = _points[0];

    if (!widget.enableCatching) {
      // ── Legacy simple follow mode ──
      if (!_following) {
        if (mouseActive && dist < widget.followRadius) _following = true;
      } else if (!mouseActive || dist > widget.followRadius * 1.5) {
        _following = false;
        _home = _points[0];
        _pickWaypoint();
      }

      if (_following) {
        final f = 1 - math.pow(1 - 0.12, dt).toDouble();
        _points[0] = Offset.lerp(_points[0], _mouse, f)!;
      } else if (widget.roam != DragonRoam.off) {
        _roam(dt);
      }
    } else {
      // ── Advanced Attraction & Catching State Machine ──
      _tickStateMachine(dt, dtSeconds, mouseActive, dist);
    }

    final delta = _points[0] - prevHead;
    final moved = delta.distance;
    if (moved > 0.4 && _state != _DragonState.notice) {
      _roamAngle = math.atan2(delta.dy, delta.dx);
    }
    _phase += moved * 0.09;
    _speed = _speed * 0.85 + moved * 0.15;

    // Inverse kinematics spine link solver
    for (int i = 1; i < _points.length; i++) {
      final dir = _points[i - 1] - _points[i];
      final d = dir.distance;
      if (d > 0.001) {
        _points[i] = _points[i - 1] - dir / d * widget.spacing;
      }
    }

    // Expanding catch ring animation & flash decay
    if (_catchRingRadius > 0) {
      _catchRingRadius += dt * 2.4;
      if (_catchRingRadius > 42) _catchRingRadius = 0;
    }
    if (_snapFlash > 0) {
      _snapFlash = math.max(0.0, _snapFlash - dt * 0.07);
    }
    if (_headShake > 0) {
      _headShake = math.max(0.0, _headShake - dt * 0.04);
    }

    if (widget.showEmbers) _updateEmbers();

    _repaint.value = _time;
  }

  void _tickStateMachine(
    double dt,
    double dtSeconds,
    bool mouseActive,
    double dist,
  ) {
    switch (_state) {
      case _DragonState.roam:
        if (widget.roam != DragonRoam.off) {
          _roam(dt);
        }
        if (mouseActive && dist < widget.attractRadius) {
          _state = _DragonState.notice;
          _stateTimer = 0.3; // Stare and focus for 0.3s
        }
        break;

      case _DragonState.notice:
        // Dragon stops, turns head to the cursor
        _turnToward(_mouse, 0.12 * dt);
        _stateTimer -= dtSeconds;

        if (!mouseActive || dist > widget.attractRadius * 1.35) {
          _state = _DragonState.roam;
          _home = _points[0];
          _pickWaypoint();
        } else if (_stateTimer <= 0) {
          _state = _DragonState.stalk;
        }
        break;

      case _DragonState.stalk:
        // Approach slowly in a curved snake-like path
        _turnToward(_mouse, 0.055 * dt);
        final stalkSpeed = (widget.roamSpeed * 0.85 + 0.3) * dt;
        _points[0] += Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * stalkSpeed;

        if (dist < widget.lungeDistance && mouseActive) {
          _state = _DragonState.lunge;
          _stateTimer = 0.65; // Max lunge window
        } else if (!mouseActive || dist > widget.attractRadius * 1.45) {
          _state = _DragonState.roam;
          _home = _points[0];
          _pickWaypoint();
        }
        break;

      case _DragonState.lunge:
        // Dash quickly toward the cursor with jaws open
        _turnToward(_mouse, 0.14 * dt);
        final lungeSpeed = (widget.roamSpeed * 3.4 + 2.8) * dt;
        _points[0] += Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * lungeSpeed;

        _stateTimer -= dtSeconds;
        // Hit check
        final catchRadius = (28.0 * widget.scale).clamp(18.0, 32.0);
        if (dist < catchRadius) {
          // CAUGHT!
          _state = _DragonState.snap;
          _stateTimer = 0.32;
          _snapFlash = 1.0;
          _catchRingRadius = 4.0;
          _triggerCatchBurst(_mouse);
        } else if (_stateTimer <= 0 || dist > widget.lungeDistance * 1.85) {
          // Missed! Snaps at empty air and enters recover
          _state = _DragonState.recover;
          _stateTimer = widget.catchCooldown * 0.65;
          _headShake = 1.0;
          _home = _points[0];
          _pickWaypoint();
        }
        break;

      case _DragonState.snap:
        // Jaws clamped shut; brief hold
        _stateTimer -= dtSeconds;
        if (_stateTimer <= 0) {
          _state = _DragonState.recover;
          _stateTimer = widget.catchCooldown;
          _headShake = 1.0;
          _home = _points[0];
          _pickWaypoint();
        }
        break;

      case _DragonState.recover:
        // Shake head, veer away from cursor and ignore mouse
        final awayAng = math.atan2(_points[0].dy - _mouse.dy, _points[0].dx - _mouse.dx);
        _turnTowardAngle(awayAng, 0.045 * dt);
        final step = widget.roamSpeed * dt;
        _points[0] += Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * step;

        _stateTimer -= dtSeconds;
        if (_stateTimer <= 0) {
          _state = _DragonState.roam;
          _pickWaypoint();
        }
        break;
    }
  }

  void _turnToward(Offset target, double maxTurn) {
    final to = target - _points[0];
    if (to.distance < 0.001) return;
    final desired = math.atan2(to.dy, to.dx);
    _turnTowardAngle(desired, maxTurn);
  }

  void _turnTowardAngle(double desired, double maxTurn) {
    var diff = desired - _roamAngle;
    while (diff > math.pi) {
      diff -= math.pi * 2;
    }
    while (diff < -math.pi) {
      diff += math.pi * 2;
    }
    _roamAngle += diff.clamp(-maxTurn, maxTurn).toDouble();
  }

  void _triggerCatchBurst(Offset origin) {
    if (!widget.showEmbers) return;
    const count = 14;
    for (int k = 0; k < count; k++) {
      final ang = _rng.nextDouble() * math.pi * 2;
      final spd = 1.8 + _rng.nextDouble() * 3.6;
      _embers.add(_Ember(
        origin + _jitter(4),
        Offset(math.cos(ang), math.sin(ang)) * spd,
        1.0,
        1.4 + _rng.nextDouble() * 1.8,
      ));
    }
    if (_embers.length > 80) {
      _embers.removeRange(0, _embers.length - 80);
    }
  }

  void _updateEmbers() {
    final n = _points.length;

    // Tail embers
    if (_speed > 0.8 && _rng.nextDouble() < 0.50 && _embers.length < 80) {
      _embers.add(_Ember(
        _points[n - 1] + _jitter(4),
        _jitter(0.6),
        1,
        1.2 + _rng.nextDouble() * 1.8,
      ));
    }

    // Body sparks
    if (_speed > 1.5 && _rng.nextDouble() < 0.30 && _embers.length < 80) {
      final i = 4 + _rng.nextInt(math.max(1, n - 8));
      _embers.add(_Ember(
        _points[i] + _jitter(8),
        _jitter(0.8),
        1,
        1.0 + _rng.nextDouble() * 1.5,
      ));
    }

    // Mouth sparks
    if (_speed > 3 && _rng.nextDouble() < 0.55 && _embers.length < 80) {
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

    // Attraction stream of sparks: flows from cursor toward dragon's mouth
    if (widget.enableCatching &&
        (_state == _DragonState.notice || _state == _DragonState.stalk) &&
        _embers.length < 76) {
      final chance = _state == _DragonState.notice ? 0.45 : 0.25;
      if (_rng.nextDouble() < chance) {
        final toMouth = _points[0] - _mouse;
        final d = toMouth.distance;
        if (d > 2) {
          final dir = toMouth / d;
          final spd = 2.4 + _rng.nextDouble() * 2.6;
          _embers.add(_Ember(
            _mouse + _jitter(4),
            dir * spd + _jitter(0.5),
            1.0,
            1.1 + _rng.nextDouble() * 1.3,
          ));
        }
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
    if (e.kind == PointerDeviceKind.touch) {
      _isTouch = true;
      return;
    }
    _hasPointer = true;
    _mouseInWindow = true;
    _rawMouse = e.localPosition;
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
    _turnTowardAngle(desired, 0.05 * dt);

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
    final hideCursor = !_isTouch &&
        widget.hideSystemCursor &&
        widget.cursorStyle != DragonCursorStyle.system &&
        _hasPointer &&
        _mouseInWindow;

    return MouseRegion(
      opaque: false,
      cursor: hideCursor ? SystemMouseCursors.none : MouseCursor.defer,
      onEnter: (_) => _mouseInWindow = true,
      onExit: (_) => _mouseInWindow = false,
      child: Listener(
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
                      stateOf: () => _state,
                      rawMouseOf: () => _rawMouse,
                      hasPointerOf: () => _hasPointer,
                      mouseInWindowOf: () => _mouseInWindow,
                      isTouchOf: () => _isTouch,
                      snapFlashOf: () => _snapFlash,
                      catchRingRadiusOf: () => _catchRingRadius,
                      headShakeOf: () => _headShake,
                      scale: widget.scale,
                      bone: widget.boneColor,
                      glow: widget.glowColor,
                      softGlow: widget.softGlow,
                      cursorStyle: widget.cursorStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
  final _DragonState Function() stateOf;
  final Offset Function() rawMouseOf;
  final bool Function() hasPointerOf;
  final bool Function() mouseInWindowOf;
  final bool Function() isTouchOf;
  final double Function() snapFlashOf;
  final double Function() catchRingRadiusOf;
  final double Function() headShakeOf;

  final double scale;
  final Color bone;
  final Color glow;
  final bool softGlow;
  final DragonCursorStyle cursorStyle;

  _DragonPainter({
    required this.points,
    required this.embers,
    required this.timeOf,
    required this.phaseOf,
    required this.speedOf,
    required this.stateOf,
    required this.rawMouseOf,
    required this.hasPointerOf,
    required this.mouseInWindowOf,
    required this.isTouchOf,
    required this.snapFlashOf,
    required this.catchRingRadiusOf,
    required this.headShakeOf,
    required this.scale,
    required this.bone,
    required this.glow,
    required this.softGlow,
    required this.cursorStyle,
    required Listenable repaint,
  }) : super(repaint: repaint);

  Color get boneDark => Color.lerp(bone, Colors.black, 0.45)!;

  // Reusable paints to avoid per-frame allocations
  final Paint _fill = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _stroke(Color c, double w) => _strokePaint
    ..color = c
    ..strokeWidth = w
    ..maskFilter = null;

  Paint _blur(Color c, double sigma) {
    _fill.color = c;
    if (softGlow) {
      _fill.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    } else {
      _fill.maskFilter = null;
    }
    return _fill;
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

    // Bait cursor drawn on top in exact 1:1 screen coordinates
    _drawBaitCursor(canvas, t);
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

      // Dorsal spike
      final len = 4 + 9 * taper;
      final spike = Path()
        ..moveTo(p.dx + tx * 2.5, p.dy + ty * 2.5)
        ..lineTo(p.dx + nx * 1.8, p.dy + ny * 1.8)
        ..lineTo(p.dx - tx * len, p.dy - ty * len)
        ..lineTo(p.dx - nx * 1.8, p.dy - ny * 1.8)
        ..close();
      _fill.color = glow.withAlpha(200);
      _fill.maskFilter = null;
      canvas.drawPath(spike, _fill);

      // Vertebra
      _fill.color = col;
      canvas.drawCircle(p, 1.6 + 3.4 * taper, _fill);

      // Ribs on the torso
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

          _fill.color = glow.withAlpha(220);
          canvas.drawCircle(end, 1.1, _fill);
        }
      }

      // Side spikes on the tail
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
    _fill.color = glow.withAlpha(190);
    _fill.maskFilter = null;
    canvas.drawPath(blade, _fill);
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

    // Glowing membrane
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

    // Veins
    final vein = _stroke(bone.withAlpha(70), 0.8);
    canvas.drawLine(elbow, Offset.lerp(tips[0], tips[1], 0.5)!, vein);
    canvas.drawLine(elbow, Offset.lerp(tips[1], tips[2], 0.5)!, vein);
    canvas.drawLine(anchor, Offset.lerp(tips[2], back, 0.5)!, vein);

    // Bones
    canvas.drawLine(anchor, elbow, _stroke(bone, 2.8));
    final fingerPaint = _stroke(bone, 1.8);
    for (final tip in tips) {
      canvas.drawLine(elbow, tip, fingerPaint);
      canvas.drawCircle(tip, 2.2, _blur(glow.withAlpha(230), 1.5));
    }
    _fill.color = bone;
    _fill.maskFilter = null;
    canvas.drawCircle(elbow, 3, _fill);
    _fill.color = glow;
    canvas.drawCircle(elbow, 1.4, _fill);
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

    _fill.color = bone;
    _fill.maskFilter = null;
    canvas.drawCircle(anchor, 4.5, _fill);
    canvas.drawCircle(joint, 3.2, _fill);
    canvas.drawCircle(wrist, 2.6, _fill);

    _fill.color = glow;
    canvas.drawCircle(anchor, 1.8, _fill);
    canvas.drawCircle(joint, 1.3, _fill);

    final fingerPaint = _stroke(bone, 1.6);
    final clawPaint = _stroke(Color.lerp(bone, glow, 0.6)!, 1.4);

    for (int k = 0; k < 4; k++) {
      final ang = lowerAngle + (k - 1.5) * 0.38;
      final knuckle = wrist + Offset(math.cos(ang), math.sin(ang)) * 9;
      final clawAng = ang + side * 0.5;
      final tip = knuckle + Offset(math.cos(clawAng), math.sin(clawAng)) * 5;

      canvas.drawLine(wrist, knuckle, fingerPaint);
      canvas.drawLine(knuckle, tip, clawPaint);
      _fill.color = bone;
      canvas.drawCircle(knuckle, 1.3, _fill);
    }
  }

  // ------------------------------------------------------------------ head
  void _drawHead(Canvas canvas, double t) {
    final head = points[0];
    final a = _heading(0);
    final state = stateOf();
    final fire = ((speedOf() - 2.8) / 6).clamp(0.0, 1.0).toDouble();
    final pulse = 0.75 + 0.25 * math.sin(t * 4);
    final headShake = headShakeOf();

    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(a);

    // Subtle head oscillation when recovering from snapping
    if (headShake > 0) {
      canvas.rotate(math.sin(t * 30) * 0.22 * headShake);
    }

    // Soft glow under the head
    if (softGlow) {
      canvas.drawCircle(
        const Offset(10, 0),
        26,
        _blur(glow.withAlpha(40), 14),
      );
    }

    // Whiskers
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

    // Horns with glowing tips
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

    // Skull
    final skull = Path()
      ..moveTo(-12, 0)
      ..cubicTo(-12, -13, 8, -13, 24, -5)
      ..lineTo(34, -3)
      ..lineTo(34, 3)
      ..lineTo(24, 5)
      ..cubicTo(8, 13, -12, 13, -12, 0)
      ..close();

    _fill.color = const Color(0xFF14141C);
    _fill.maskFilter = null;
    canvas.drawPath(skull, _fill);
    canvas.drawPath(skull, _stroke(bone, 2));

    // Crest diamond
    final crest = Path()
      ..moveTo(-7, 0)
      ..lineTo(0, -3)
      ..lineTo(8, 0)
      ..lineTo(0, 3)
      ..close();
    _fill.color = glow.withAlpha(170);
    canvas.drawPath(crest, _fill);

    // Mouth + teeth opening depending on state
    double mouthOpen;
    switch (state) {
      case _DragonState.lunge:
        mouthOpen = 6.8; // Jaws wide open during lunge!
        break;
      case _DragonState.stalk:
        mouthOpen = 2.6 + math.sin(t * 4) * 0.8;
        break;
      case _DragonState.snap:
        mouthOpen = 0.0; // Clamped shut!
        break;
      case _DragonState.notice:
        mouthOpen = 1.0;
        break;
      default:
        mouthOpen = (math.sin(t * 2.5) * 0.5 + 0.5) * 1.5 + fire * 3;
    }

    canvas.drawLine(const Offset(8, 0), const Offset(34, 0), _stroke(bone, 1.2));
    final tooth = _stroke(bone, 1.5);
    for (double x = 14; x <= 32; x += 4) {
      final y = 3.2 - (x - 14) * 0.08;
      canvas.drawLine(Offset(x, y), Offset(x + 0.6, y + 2.5 + mouthOpen), tooth);
      canvas.drawLine(
          Offset(x, -y), Offset(x + 0.6, -y - 2.5 - mouthOpen), tooth);
    }

    // Eyes + nostrils (eyes grow larger & brighter when noticing or stalking)
    final isNoticing = state == _DragonState.notice || state == _DragonState.stalk;
    final eyeScale = isNoticing ? 1.35 : 1.0;
    final eyeAlpha = isNoticing ? 255 : (170 * pulse).round();

    for (final s in [-1.0, 1.0]) {
      _fill.color = Colors.black;
      _fill.maskFilter = null;
      canvas.drawCircle(Offset(4, 6 * s), 4.2 * eyeScale, _fill);
      canvas.drawCircle(
        Offset(4, 6 * s),
        6.5 * eyeScale,
        _blur(glow.withAlpha(eyeAlpha), 5),
      );
      _fill.color = glow;
      _fill.maskFilter = null;
      canvas.drawCircle(Offset(4.5, 6 * s), 2.2 * eyeScale, _fill);
      _fill.color = const Color(0xFFFFF1B8);
      canvas.drawCircle(
        Offset(4.8, 6 * s),
        1.1 * eyeScale,
        _fill,
      );
      _fill.color = Colors.black;
      canvas.drawCircle(Offset(29, 1.6 * s), 0.9, _fill);
    }

    // Brow ridge
    canvas.drawLine(const Offset(-2, -9), const Offset(12, -8), _stroke(bone, 1.4));
    canvas.drawLine(const Offset(-2, 9), const Offset(12, 8), _stroke(bone, 1.4));

    // Fire breath when moving fast
    if (fire > 0.08 && state != _DragonState.snap) {
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

  // ---------------------------------------------------------- bait cursor
  void _drawBaitCursor(Canvas canvas, double t) {
    if (cursorStyle == DragonCursorStyle.system) return;
    if (isTouchOf() || !hasPointerOf() || !mouseInWindowOf()) return;

    final pos = rawMouseOf();
    if (pos.dx < 0 || pos.dy < 0) return;

    final flash = snapFlashOf(); // 1.0 -> 0.0 flash when caught
    final ringR = catchRingRadiusOf();
    final state = stateOf();
    final isNoticing = state == _DragonState.notice || state == _DragonState.stalk;
    final isLunge = state == _DragonState.lunge;

    // Expanding snap ring effect when caught
    if (ringR > 0 && ringR < 45) {
      final ringAlpha = (1.0 - ringR / 45.0).clamp(0.0, 1.0);
      _strokePaint
        ..color = glow.withAlpha((ringAlpha * 230).round())
        ..strokeWidth = 1.8
        ..maskFilter = null;
      canvas.drawCircle(pos, ringR, _strokePaint);
    }

    if (cursorStyle == DragonCursorStyle.ember) {
      _drawEmberCursor(canvas, pos, t, flash, isNoticing, isLunge);
    } else if (cursorStyle == DragonCursorStyle.orb) {
      _drawOrbCursor(canvas, pos, t, flash, isNoticing, isLunge);
    }
  }

  void _drawEmberCursor(
    Canvas canvas,
    Offset pos,
    double t,
    double flash,
    bool isNoticing,
    bool isLunge,
  ) {
    // Outer glow circles (faked with lightweight translucent circles)
    final outerAlpha = isNoticing ? 90 : 50;
    final midAlpha = isNoticing ? 160 : 100;
    _fill.maskFilter = null;

    _fill.color = glow.withAlpha(outerAlpha);
    canvas.drawCircle(pos, 11.0 + (isNoticing ? 3.0 : 0.0), _fill);

    _fill.color = glow.withAlpha(midAlpha);
    canvas.drawCircle(pos, 6.5 + (isNoticing ? 2.0 : 0.0), _fill);

    // Rotating thin ring with 2 arcs
    final rot = t * (isLunge ? 8.0 : (isNoticing ? 5.0 : 3.0));
    final ringRadius = 11.5 + (isNoticing ? 2.0 : 0.0);
    _strokePaint
      ..color = (flash > 0.1 ? Colors.white : glow).withAlpha(isNoticing ? 220 : 160)
      ..strokeWidth = 1.0
      ..maskFilter = null;

    final rect = Rect.fromCircle(center: pos, radius: ringRadius);
    canvas.drawArc(rect, rot, math.pi * 0.72, false, _strokePaint);
    canvas.drawArc(rect, rot + math.pi, math.pi * 0.72, false, _strokePaint);

    // 3 tiny orbiting sparks
    for (int i = 0; i < 3; i++) {
      final ang = -rot * 0.8 + (i * math.pi * 2 / 3);
      final spDist = ringRadius + 2.5 + math.sin(t * 5 + i) * 1.5;
      final sp = pos + Offset(math.cos(ang), math.sin(ang)) * spDist;
      _fill.color = const Color(0xFFFFD57A).withAlpha(220);
      canvas.drawCircle(sp, 1.1, _fill);
    }

    // Center ember core (shrinks slightly on flash, then restores)
    final coreR = 3.6 * (1.0 - flash * 0.35);
    _fill.color = flash > 0.1
        ? Colors.white
        : Color.lerp(glow, const Color(0xFFFFF2B2), 0.75)!;
    canvas.drawCircle(pos, coreR, _fill);

    _fill.color = Colors.white;
    canvas.drawCircle(pos, coreR * 0.55, _fill);
  }

  void _drawOrbCursor(
    Canvas canvas,
    Offset pos,
    double t,
    double flash,
    bool isNoticing,
    bool isLunge,
  ) {
    // Shimmering mystical orb
    final rot = t * (isLunge ? 6.0 : (isNoticing ? 4.5 : 2.5));
    _fill.maskFilter = null;

    _fill.color = glow.withAlpha(isNoticing ? 80 : 45);
    canvas.drawCircle(pos, 13.0, _fill);

    _fill.color = glow.withAlpha(isNoticing ? 160 : 110);
    canvas.drawCircle(pos, 7.5, _fill);

    // Orbit ellipse ring
    _strokePaint
      ..color = (flash > 0.1 ? Colors.white : glow).withAlpha(180)
      ..strokeWidth = 1.0
      ..maskFilter = null;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rot);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 26, height: 12),
      _strokePaint,
    );

    // Orbiting satellite motes
    final m1 = Offset(math.cos(rot * 2) * 13, math.sin(rot * 2) * 6);
    final m2 = Offset(-m1.dx, -m1.dy);
    _fill.color = const Color(0xFFFFF1C2);
    canvas.drawCircle(m1, 1.2, _fill);
    canvas.drawCircle(m2, 1.0, _fill);
    canvas.restore();

    // Central orb sphere
    final orbR = 4.4 * (1.0 - flash * 0.3);
    _fill.color = flash > 0.1
        ? Colors.white
        : Color.lerp(glow, const Color(0xFFE6F4FF), 0.65)!;
    canvas.drawCircle(pos, orbR, _fill);

    // Specular highlight
    _fill.color = Colors.white;
    canvas.drawCircle(Offset(pos.dx - 1.2, pos.dy - 1.2), orbR * 0.45, _fill);
  }

  @override
  bool shouldRepaint(covariant _DragonPainter oldDelegate) => true;
}
