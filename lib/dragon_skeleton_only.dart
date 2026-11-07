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

/// Internal states of the dragon attraction, catching, feeding and sleeping machine.
enum _DragonState {
  roam,
  notice,
  stalk,
  lunge,
  snap,
  recover,
  feed, // flying to a piece of food you dropped
  eat, // chewing it
  goSleep, // flying to a corner to curl up
  sleep, // curled up, breathing, zzz
  wake, // eye opens, stretch, yawn, take off
}

/// Wrap any page with this widget and a glowing dragon skeleton follows the mouse
/// or hunts the glowing bait cursor. Click anywhere to drop food for the dragon.
/// If you leave the mouse alone, the dragon curls up in a corner and sleeps.
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
///   attractRadius: 200,
///   lungeDistance: 90,
///   catchCooldown: 2.5,
///   enableFeeding: true,                  // click = drop food
///   maxFood: 3,
///   foodLifetime: 12,
///   happyDuration: 10,
///   enableSleep: true,                    // sleep when the mouse is idle
///   sleepAfter: 8,                        // seconds without mouse movement
///   startAsleep: true,                    // already asleep when the page opens
///   wakeSpeed: 350,                       // px/s mouse speed needed to wake it
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

  /// Click (or tap) drops a glowing ember of food. The dragon flies to it,
  /// eats it and burps fire. Eating makes it happy for a while.
  final bool enableFeeding;

  /// Set false if you do not want clicks to drop food.
  final bool feedOnClick;

  /// How many pieces of food can lie on the screen at once.
  final int maxFood;

  /// Seconds a piece of food stays before it fades away.
  final double foodLifetime;

  /// Seconds the dragon stays happy (longer fire trail, faster, bigger wings).
  final double happyDuration;

  /// The dragon curls up and sleeps in a corner after [sleepAfter] seconds
  /// without any mouse movement or click. Moving the mouse wakes it up.
  final bool enableSleep;

  /// Seconds without mouse activity before the dragon falls asleep.
  final double sleepAfter;

  /// The dragon is already curled up asleep (random corner) when the
  /// page first opens. Any mouse move, click or touch wakes it up.
  final bool startAsleep;

  /// A sleeping dragon only wakes from mouse movement faster than this
  /// (screen pixels per second). Tiny, slow moves are ignored. Clicks, touches
  /// and scrolling always wake it.
  final double wakeSpeed;

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
    this.attractRadius = 200,
    this.lungeDistance = 90,
    this.catchCooldown = 2.5,
    this.enableFeeding = true,
    this.feedOnClick = true,
    this.maxFood = 3,
    this.foodLifetime = 12,
    this.happyDuration = 10,
    this.enableSleep = true,
    this.sleepAfter = 8,
    this.startAsleep = true,
    this.wakeSpeed = 350,
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

/// A piece of food dropped by a click (positions are in dragon space).
class _Food {
  Offset pos;
  final double born;
  double life; // seconds left before it fades away
  double shrink = 1.0; // 1 -> 0 while being eaten
  _Food(this.pos, this.born, this.life);
}

/// Visual values for the sleeping dragon, read by the painter.
class _SleepFx {
  double fold = 0; // 0 awake .. 1 tucked (wings, limbs, ribs folded)
  double eyeA = 1; // eyelid openness of each eye (0 closed .. 1 open)
  double eyeB = 1;
  double yawn = 0;
  double stretch = 0;
  double look = 0; // head turn in radians (looking around)
  double wing = 0; // single wing flap 0..1
  double zzz = 0; // visibility of the z marks
  double breath = 0; // -1..1
  Offset center = Offset.zero; // coil center
}

class _DragonSkeletonCursorState extends State<DragonSkeletonCursor>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<Offset> _points;
  final List<_Ember> _embers = [];
  final List<_Food> _foods = [];
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

  // Feeding
  double _eatTimer = 0.0;
  _Food? _eatingFood;
  double _happy = 0.0; // 0..1, grows with every meal
  double _happyTimer = 0.0;
  double _burp = 0.0; // 1 -> 0 fire puff after eating

  // Sleeping
  final _SleepFx _fx = _SleepFx();
  double _lastActivity = 0;
  bool _wakeRequested = false;
  Offset _coilCenter = Offset.zero;
  List<Offset> _coilOffsets = const [];
  int _idleKind = 0; // 0 none, 1 look around, 2 wing flap
  double _idleT = 0;
  double _nextIdleAt = 2;
  bool _initialSleepDone = false;
  Offset _prevRaw = const Offset(-999, -999);
  Duration _prevStamp = Duration.zero;
  int _lastCorner = -1; // 0 top-left, 1 top-right, 2 bottom-right, 3 bottom-left

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

  // A happy dragon flies faster and leaves a longer fire trail.
  double get _roamSpeed => widget.roamSpeed * (1 + 0.3 * _happy);
  int get _maxEmbers => 80 + (_happy * 70).round();

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

    // First build: start the page with the dragon already asleep.
    if (!_initialSleepDone) {
      _initialSleepDone = true;
      if (widget.enableSleep && widget.startAsleep) _startAsleep();
    }
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

    _fx.breath = math.sin(_time * 1.1);

    // Food has priority over everything except a lunge / snap in progress.
    final feeding = _updateFeeding(dt, dtSeconds);
    final sleeping = !feeding && _updateSleep(dt, dtSeconds);

    if (!feeding && !sleeping) {
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
    }

    final delta = _points[0] - prevHead;
    final moved = delta.distance;
    if (!_isCoiled && moved > 0.4 && _state != _DragonState.notice) {
      _roamAngle = math.atan2(delta.dy, delta.dx);
    }
    if (!_isCoiled) _phase += moved * 0.09;
    _speed = _isCoiled ? _speed * 0.8 : _speed * 0.85 + moved * 0.15;

    // Inverse kinematics spine link solver (paused while curled up)
    if (!_isCoiled) {
      for (int i = 1; i < _points.length; i++) {
        final dir = _points[i - 1] - _points[i];
        final d = dir.distance;
        if (d > 0.001) {
          _points[i] = _points[i - 1] - dir / d * widget.spacing;
        }
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

    // happiness fades after a while, burp fades quickly
    if (_happyTimer > 0) {
      _happyTimer -= dtSeconds;
    } else if (_happy > 0) {
      _happy = math.max(0.0, _happy - dtSeconds * 0.25);
    }
    if (_burp > 0) {
      _burp = math.max(0.0, _burp - dtSeconds * 2.2);
    }

    if (widget.showEmbers) _updateEmbers();

    _wakeRequested = false;
    _repaint.value = _time;
  }

  // ───────────────────────────────────────────────────────────── sleeping
  bool get _isCoiled =>
      _state == _DragonState.sleep || _state == _DragonState.wake;

  double _ease(double rate, double dt) =>
      1 - math.pow(1 - rate, dt).toDouble();

  /// Returns true when sleeping controls the dragon this frame.
  bool _updateSleep(double dt, double dtSeconds) {
    if (!widget.enableSleep) return false;
    final idle = _time - _lastActivity;

    switch (_state) {
      case _DragonState.roam:
        {
          if (idle > widget.sleepAfter && _foods.isEmpty && !_following) {
            _beginSleepWalk();
            return true;
          }
          // A dragon that stands still (roam: off) fidgets a little.
          if (widget.roam == DragonRoam.off && !_following) {
            _idleMoves(dtSeconds, allowLook: true, gap: 3.5);
          } else {
            _stopIdle();
          }
          return false;
        }

      case _DragonState.goSleep:
        {
          if (_wakeRequested) {
            _state = _DragonState.roam;
            _home = _points[0];
            _pickWaypoint();
            return true;
          }
          _stateTimer += dtSeconds;
          final target = _coilCenter + _coilOffsets.first;
          final d = (target - _points[0]).distance;
          _turnToward(target, (d < 90 ? 0.2 : 0.07) * dt);
          final slow = (d / 90).clamp(0.4, 1.0).toDouble();
          _points[0] += Offset(math.cos(_roamAngle), math.sin(_roamAngle)) *
              (_roamSpeed * 1.1 * dt * slow);
          if (d < 20 || _stateTimer > 9) _enterSleep();
          return true;
        }

      case _DragonState.sleep:
        {
          if (_wakeRequested) {
            _state = _DragonState.wake;
            _stateTimer = 0;
            _stopIdle();
            return true;
          }
          _stateTimer += dtSeconds;
          final drowsy = _stateTimer < 3.5;
          _settleIntoCoil(dt);

          _fx.fold += (1 - _fx.fold) * _ease(0.03, dt);
          final lid = _stateTimer < 2.2 ? 0.55 : 0.0; // sleepy slits, then shut
          _fx.eyeA += (lid - _fx.eyeA) * _ease(0.05, dt);
          _fx.eyeB += (lid - _fx.eyeB) * _ease(0.05, dt);
          final zTarget = _stateTimer > 1.6 ? 1.0 : 0.0;
          _fx.zzz += (zTarget - _fx.zzz) * _ease(0.04, dt);

          // drowsy: looks around and flaps a wing; deep sleep: rare wing twitch
          _idleMoves(dtSeconds, allowLook: drowsy, gap: drowsy ? 1.6 : 8);
          return true;
        }

      case _DragonState.wake:
        {
          _stateTimer += dtSeconds;
          final w = _stateTimer;
          _settleIntoCoil(dt);

          _fx.eyeA = (w / 0.7).clamp(0.0, 1.0).toDouble(); // one eye opens...
          _fx.eyeB =
              ((w - 0.7) / 0.5).clamp(0.0, 1.0).toDouble(); // ...then the other
          _fx.fold = math.min(
            _fx.fold,
            (1 - (w - 0.6) / 0.8).clamp(0.0, 1.0).toDouble(),
          );
          final sp = ((w - 1.0) / 1.6).clamp(0.0, 1.0).toDouble();
          _fx.stretch = math.sin(math.pi * sp); // stretch
          final yp = ((w - 1.2) / 1.2).clamp(0.0, 1.0).toDouble();
          _fx.yawn = math.sin(math.pi * yp); // yawn
          _fx.zzz = math.max(0.0, _fx.zzz - dtSeconds * 2);

          if (w >= 2.9) _finishWake();
          return true;
        }

      default:
        _stopIdle();
        return false;
    }
  }

  /// A random corner, never the same one the dragon slept in last time.
  int _pickCorner() {
    int c;
    do {
      c = _rng.nextInt(4);
    } while (c == _lastCorner);
    _lastCorner = c;
    return c;
  }

  /// Builds the coil and puts it in [corner].
  void _prepareCoil(int corner) {
    _buildCoil();
    var maxR = 0.0;
    for (final o in _coilOffsets) {
      maxR = math.max(maxR, o.distance);
    }
    final m = maxR + 45;
    final s = _cachedSize;
    final left = corner == 0 || corner == 3;
    final top = corner == 0 || corner == 1;
    final cx = left ? m : math.max(m, s.width - m);
    final cy = top ? m : math.max(m, s.height - m);
    _coilCenter = Offset(cx, cy);
    _fx.center = _coilCenter;
  }

  void _beginSleepWalk() {
    _prepareCoil(_pickCorner());
    _state = _DragonState.goSleep;
    _stateTimer = 0;
    _stopIdle();
  }

  /// The page opens with the dragon already curled up in a random corner.
  void _startAsleep() {
    _prepareCoil(_pickCorner());
    for (int i = 0; i < _points.length; i++) {
      _points[i] = _coilCenter + _coilOffsets[i];
    }
    _state = _DragonState.sleep;
    _stateTimer = 10; // already past the drowsy phase
    _fx
      ..fold = 1
      ..eyeA = 0
      ..eyeB = 0
      ..zzz = 1;
    final d = _coilOffsets[0] - _coilOffsets[1];
    _roamAngle = math.atan2(d.dy, d.dx);
    _nextIdleAt = 5;
  }

  void _enterSleep() {
    _state = _DragonState.sleep;
    _stateTimer = 0;
    final d = _coilOffsets[0] - _coilOffsets[1];
    _roamAngle = math.atan2(d.dy, d.dx);
    _nextIdleAt = _time + 0.8;
  }

  void _finishWake() {
    _fx
      ..fold = 0
      ..eyeA = 1
      ..eyeB = 1
      ..yawn = 0
      ..stretch = 0
      ..look = 0
      ..wing = 0
      ..zzz = 0;
    _state = _DragonState.roam;
    _home = _points[0];
    _pickWaypoint();
    _burp = 0.7; // little puff of fire as it takes off
    _spawnBurp();
  }

  /// Spiral with the tail in the middle and the head resting on the outside.
  void _buildCoil() {
    final n = _points.length;
    const r0 = 14.0;
    const pitch = 26.0;
    const b = pitch / (2 * math.pi);
    final offs = List<Offset>.filled(n, Offset.zero);
    var theta = 0.0;
    for (int k = 0; k < n; k++) {
      final r = r0 + b * theta;
      offs[n - 1 - k] = Offset(math.cos(theta), math.sin(theta)) * r;
      theta += widget.spacing / r;
    }
    _coilOffsets = offs;
  }

  /// Eases every bone into the coil. The coil swells with each breath.
  void _settleIntoCoil(double dt) {
    final f = _ease(0.07, dt);
    final k = 1 + 0.025 * _fx.breath + 0.2 * _fx.stretch;
    for (int i = 0; i < _points.length; i++) {
      final target = _coilCenter + _coilOffsets[i] * k;
      _points[i] = Offset.lerp(_points[i], target, f)!;
    }
  }

  void _idleMoves(double dtSeconds,
      {required bool allowLook, required double gap}) {
    if (_idleKind == 0) {
      if (_time >= _nextIdleAt) {
        _idleKind = (allowLook && _rng.nextBool()) ? 1 : 2;
        _idleT = 0;
      }
      return;
    }
    _idleT += dtSeconds;
    final dur = _idleKind == 1 ? 2.4 : 1.6;
    final p = (_idleT / dur).clamp(0.0, 1.0).toDouble();
    final env = math.sin(math.pi * p);
    if (_idleKind == 1) {
      _fx.look = math.sin(p * math.pi * 2) * 0.55 * env; // left, then right
    } else {
      _fx.wing = env; // one wing lifts and flutters
    }
    if (_idleT >= dur) {
      _stopIdle();
      _nextIdleAt = _time + gap * (0.7 + 0.6 * _rng.nextDouble());
    }
  }

  void _stopIdle() {
    if (_idleKind == 0) return;
    _idleKind = 0;
    _fx.look = 0;
    _fx.wing = 0;
  }

  // ───────────────────────────────────────────────────────────── feeding
  Offset get _mouthPos =>
      _points[0] + Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * 30;

  /// Returns true when feeding controls the head this frame.
  bool _updateFeeding(double dt, double dtSeconds) {
    // food slowly fades away if nobody eats it
    for (final f in _foods) {
      f.life -= dtSeconds;
    }
    _foods.removeWhere((f) => f.life <= 0 && f != _eatingFood);

    if (!widget.enableFeeding) return false;

    // chewing: the head holds still and the food is sucked into the mouth
    if (_state == _DragonState.eat) {
      final food = _eatingFood;
      _eatTimer -= dtSeconds;
      if (food != null) {
        food.pos = Offset.lerp(food.pos, _mouthPos, 0.3)!;
        food.shrink = (_eatTimer / 0.45).clamp(0.0, 1.0).toDouble();
      }
      if (_eatTimer <= 0) _finishEating();
      return true;
    }

    final canFeed = _state == _DragonState.roam ||
        _state == _DragonState.notice ||
        _state == _DragonState.stalk ||
        _state == _DragonState.recover ||
        _state == _DragonState.feed;

    if (_foods.isEmpty) {
      if (_state == _DragonState.feed) {
        _state = _DragonState.roam;
        _home = _points[0];
        _pickWaypoint();
      }
      return false;
    }
    if (!canFeed) return false;

    // go for the nearest piece of food
    final mouth = _mouthPos;
    _Food target = _foods.first;
    double best = double.infinity;
    for (final f in _foods) {
      final d = (f.pos - mouth).distance;
      if (d < best) {
        best = d;
        target = f;
      }
    }

    _state = _DragonState.feed;
    _turnToward(target.pos, 0.16 * dt);
    final slow = best < 50 ? math.max(0.5, best / 50) : 1.0;
    final speed = (_roamSpeed * 2.4 + 2.0) * dt * slow;
    _points[0] += Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * speed;

    if (best < 14) {
      _state = _DragonState.eat;
      _eatTimer = 0.45;
      _eatingFood = target;
    }
    return true;
  }

  void _finishEating() {
    final food = _eatingFood;
    if (food != null) _foods.remove(food);
    _eatingFood = null;

    _happy = math.min(1.0, _happy + 0.34);
    _happyTimer = widget.happyDuration;
    _burp = 1.0;
    _spawnBurp();

    _state = _DragonState.roam;
    _home = _points[0];
    _pickWaypoint();
  }

  void _spawnBurp() {
    if (!widget.showEmbers) return;
    final dir = Offset(math.cos(_roamAngle), math.sin(_roamAngle));
    for (int k = 0; k < 12; k++) {
      final spd = 2.5 + _rng.nextDouble() * 3.5;
      _embers.add(_Ember(
        _points[0] + dir * 38 + _jitter(3),
        dir * spd + _jitter(1.0),
        1.0,
        1.6 + _rng.nextDouble() * 1.8,
      ));
    }
    if (_embers.length > _maxEmbers) {
      _embers.removeRange(0, _embers.length - _maxEmbers);
    }
  }

  void _dropFood(Offset p) {
    _foods.add(_Food(p, _time, widget.foodLifetime));
    // too much food: remove the oldest one that is not being eaten
    while (_foods.length > widget.maxFood) {
      final idx = _foods.indexWhere((f) => f != _eatingFood);
      if (idx < 0) break;
      _foods.removeAt(idx);
    }
    // little pop of sparks where the food lands
    if (widget.showEmbers) {
      for (int k = 0; k < 6; k++) {
        final ang = _rng.nextDouble() * math.pi * 2;
        final spd = 1.0 + _rng.nextDouble() * 2.2;
        _embers.add(_Ember(
          p + _jitter(3),
          Offset(math.cos(ang), math.sin(ang)) * spd,
          1.0,
          1.2 + _rng.nextDouble() * 1.4,
        ));
      }
    }
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
        final stalkSpeed = (_roamSpeed * 0.85 + 0.3) * dt;
        _points[0] +=
            Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * stalkSpeed;

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
        final lungeSpeed = (_roamSpeed * 3.4 + 2.8) * dt;
        _points[0] +=
            Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * lungeSpeed;

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
        final awayAng =
            math.atan2(_points[0].dy - _mouse.dy, _points[0].dx - _mouse.dx);
        _turnTowardAngle(awayAng, 0.045 * dt);
        final step = _roamSpeed * dt;
        _points[0] += Offset(math.cos(_roamAngle), math.sin(_roamAngle)) * step;

        _stateTimer -= dtSeconds;
        if (_stateTimer <= 0) {
          _state = _DragonState.roam;
          _pickWaypoint();
        }
        break;

      case _DragonState.feed:
      case _DragonState.eat:
      case _DragonState.goSleep:
      case _DragonState.sleep:
      case _DragonState.wake:
        // Controlled by _updateFeeding / _updateSleep. If we land here, just roam.
        _state = _DragonState.roam;
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
    if (_embers.length > _maxEmbers) {
      _embers.removeRange(0, _embers.length - _maxEmbers);
    }
  }

  void _updateEmbers() {
    final n = _points.length;
    final cap = _maxEmbers;

    // Tail embers (a happy dragon leaves more of them)
    if (_speed > 0.8 &&
        _rng.nextDouble() < 0.50 + 0.35 * _happy &&
        _embers.length < cap) {
      _embers.add(_Ember(
        _points[n - 1] + _jitter(4),
        _jitter(0.6),
        1,
        1.2 + _rng.nextDouble() * 1.8,
      ));
    }

    // Body sparks
    if (_speed > 1.5 && _rng.nextDouble() < 0.30 && _embers.length < cap) {
      final i = 4 + _rng.nextInt(math.max(1, n - 8));
      _embers.add(_Ember(
        _points[i] + _jitter(8),
        _jitter(0.8),
        1,
        1.0 + _rng.nextDouble() * 1.5,
      ));
    }

    // Happy fire trail: sparks from the whole body, they last longer
    if (_happy > 0.05 &&
        _speed > 0.5 &&
        _rng.nextDouble() < 0.55 * _happy &&
        _embers.length < cap) {
      final i = _rng.nextInt(n);
      _embers.add(_Ember(
        _points[i] + _jitter(6),
        _jitter(0.7),
        1,
        1.4 + _rng.nextDouble() * 2.0,
      ));
    }

    // Mouth sparks
    if (_speed > 3 && _rng.nextDouble() < 0.55 && _embers.length < cap) {
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
        _embers.length < cap - 4) {
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

    final decay = 0.022 * (1 - 0.4 * _happy);
    for (final e in _embers) {
      e.pos += e.vel;
      e.vel = e.vel * 0.96 + _jitter(0.08);
      e.life -= decay;
    }
    _embers.removeWhere((e) => e.life <= 0);
    if (_embers.length > cap) {
      _embers.removeRange(0, _embers.length - cap);
    }
  }

  /// Wakes a sleeping dragon (and counts as "not idle").
  void _poke() {
    _lastActivity = _time;
    _wakeRequested = true;
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) _poke(); // mouse wheel / scroll wakes it
  }

  void _updateTarget(PointerEvent e) {
    if (e.kind == PointerDeviceKind.touch) {
      _isTouch = true;
      _poke(); // touch drag / scroll
      return;
    }

    // Mouse: only a reasonably fast move wakes the dragon.
    _lastActivity = _time; // any movement still keeps an awake dragon awake
    final dt =
        ((e.timeStamp - _prevStamp).inMicroseconds / 1e6).clamp(0.004, 0.1);
    final moved = (e.localPosition - _prevRaw).distance;
    if (_prevRaw.dx > -900 && moved / dt > widget.wakeSpeed) {
      _wakeRequested = true;
    }
    _prevRaw = e.localPosition;
    _prevStamp = e.timeStamp;

    _hasPointer = true;
    _mouseInWindow = true;
    _rawMouse = e.localPosition;
    _mouse = e.localPosition / widget.scale;
    _lastMove = _time;
  }

  void _onPointerDown(PointerDownEvent e) {
    _updateTarget(e);
    _poke(); // a click always wakes it
    if (!widget.enableFeeding || !widget.feedOnClick) return;
    // only the main mouse button (or a finger tap) drops food
    if (e.kind == PointerDeviceKind.mouse &&
        (e.buttons & kPrimaryMouseButton) == 0) {
      return;
    }
    _dropFood(e.localPosition / widget.scale);
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

    final step = _roamSpeed * dt;
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
        onPointerDown: _onPointerDown,
        onPointerSignal: _onPointerSignal,
        onPointerPanZoomUpdate: (_) => _poke(), // trackpad scroll
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
                      foods: _foods,
                      repaint: _repaint,
                      timeOf: () => _time,
                      phaseOf: () => _phase,
                      speedOf: () => _speed,
                      stateOf: () => _state,
                      happyOf: () => _happy,
                      burpOf: () => _burp,
                      rawMouseOf: () => _rawMouse,
                      hasPointerOf: () => _hasPointer,
                      mouseInWindowOf: () => _mouseInWindow,
                      isTouchOf: () => _isTouch,
                      snapFlashOf: () => _snapFlash,
                      catchRingRadiusOf: () => _catchRingRadius,
                      headShakeOf: () => _headShake,
                      fx: _fx,
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
  final List<_Food> foods;
  final double Function() timeOf;
  final double Function() phaseOf;
  final double Function() speedOf;
  final _DragonState Function() stateOf;
  final double Function() happyOf;
  final double Function() burpOf;
  final Offset Function() rawMouseOf;
  final bool Function() hasPointerOf;
  final bool Function() mouseInWindowOf;
  final bool Function() isTouchOf;
  final double Function() snapFlashOf;
  final double Function() catchRingRadiusOf;
  final double Function() headShakeOf;
  final _SleepFx fx;

  final double scale;
  final Color bone;
  final Color glow;
  final bool softGlow;
  final DragonCursorStyle cursorStyle;

  _DragonPainter({
    required this.points,
    required this.embers,
    required this.foods,
    required this.timeOf,
    required this.phaseOf,
    required this.speedOf,
    required this.stateOf,
    required this.happyOf,
    required this.burpOf,
    required this.rawMouseOf,
    required this.hasPointerOf,
    required this.mouseInWindowOf,
    required this.isTouchOf,
    required this.snapFlashOf,
    required this.catchRingRadiusOf,
    required this.headShakeOf,
    required this.fx,
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
    _drawFoods(canvas, t);
    _drawSleepGlow(canvas);

    // Wings
    _drawWing(canvas, 5, -1, t);
    _drawWing(canvas, 5, 1, t);

    // Front arms with hands and hind legs (tucked in while sleeping)
    final limbK = 1 - 0.5 * fx.fold;
    for (final s in [-1.0, 1.0]) {
      _drawLimb(canvas, 10, s, phase, hind: false, scale: 0.95 * limbK);
      _drawLimb(canvas, 21, s, phase, hind: true, scale: 1.1 * limbK);
    }

    _drawSpine(canvas);
    _drawBody(canvas, n);
    _drawTailBlade(canvas);
    _drawHead(canvas, t);
    _drawZzz(canvas, t);

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

  // ----------------------------------------------------------------- food
  void _drawFoods(Canvas canvas, double t) {
    for (final f in foods) {
      if (f.shrink <= 0.02) continue;

      final age = t - f.born;
      final appear = (age / 0.25).clamp(0.0, 1.0).toDouble();

      // blink and fade during the last 2 seconds
      double fadeOut = 1.0;
      if (f.life < 2.0) {
        fadeOut = (f.life / 2.0).clamp(0.0, 1.0).toDouble() *
            (0.65 + 0.35 * math.sin(t * 16));
      }
      final a = (appear * fadeOut).clamp(0.0, 1.0).toDouble();

      // the food drops in from above
      final pos = Offset(f.pos.dx, f.pos.dy - (1 - appear) * 20);
      final r = 5.5 *
          (0.7 + 0.3 * appear) *
          f.shrink *
          (1 + 0.08 * math.sin(t * 8 + f.born * 3));

      // ripple ring where it landed
      if (age < 0.6) {
        final ra = (1 - age / 0.6).clamp(0.0, 1.0).toDouble();
        _strokePaint
          ..color = glow.withAlpha((ra * 200).round())
          ..strokeWidth = 1.4
          ..maskFilter = null;
        canvas.drawCircle(f.pos, 6 + age * 70, _strokePaint);
      }

      // glow halos (plain translucent circles, no blur)
      _fill.maskFilter = null;
      _fill.color = glow.withAlpha((a * 70).round());
      canvas.drawCircle(pos, r * 2.4, _fill);
      _fill.color = glow.withAlpha((a * 130).round());
      canvas.drawCircle(pos, r * 1.55, _fill);

      // slowly turning diamond ember
      final ang = t * 2 + f.born;
      final dia = Path();
      for (int k = 0; k < 4; k++) {
        final aa = ang + k * math.pi / 2;
        final rr = k.isEven ? r * 1.15 : r * 0.8;
        final pt = pos + Offset(math.cos(aa), math.sin(aa)) * rr;
        if (k == 0) {
          dia.moveTo(pt.dx, pt.dy);
        } else {
          dia.lineTo(pt.dx, pt.dy);
        }
      }
      dia.close();
      _fill.color = Color.lerp(glow, const Color(0xFFFFF2B2), 0.7)!
          .withAlpha((a * 255).round());
      canvas.drawPath(dia, _fill);
      _fill.color = Colors.white.withAlpha((a * 255).round());
      canvas.drawCircle(pos, r * 0.38, _fill);

      // two tiny sparks orbiting the food
      for (int k = 0; k < 2; k++) {
        final oa = -t * 3 + k * math.pi;
        final sp = pos + Offset(math.cos(oa), math.sin(oa)) * (r * 1.9);
        _fill.color = const Color(0xFFFFD57A).withAlpha((a * 220).round());
        canvas.drawCircle(sp, 1.0, _fill);
      }
    }
  }

  // ------------------------------------------------------------ sleeping
  // Warm glow under the coil that swells with each breath.
  void _drawSleepGlow(Canvas canvas) {
    final f = fx.fold;
    if (f < 0.05) return;
    final b = 0.5 + 0.5 * fx.breath;
    _fill.maskFilter = null;
    _fill.color = glow.withAlpha(((16 + 22 * b) * f).round());
    canvas.drawCircle(fx.center, 92 + 8 * b, _fill);
    _fill.color = glow.withAlpha(((10 + 16 * b) * f).round());
    canvas.drawCircle(fx.center, 58 + 6 * b, _fill);
  }

  // Little "z" marks drifting up from the sleeping head.
  void _drawZzz(Canvas canvas, double t) {
    final amt = fx.zzz;
    if (amt < 0.03) return;
    final head = points[0];
    final dir = head.dy < 100 ? 1.0 : -1.0; // drift downward near the top edge
    for (int k = 0; k < 3; k++) {
      final p = (t * 0.28 + k / 3) % 1.0;
      final size = 3.5 + 7 * p;
      final alpha = (math.sin(math.pi * p) * amt * 230).round();
      if (alpha <= 2) continue;
      final c = head +
          Offset(16 + 22 * p + math.sin(t * 1.6 + k * 2) * 3,
              dir * (18 + 52 * p));
      final z = Path()
        ..moveTo(c.dx - size, c.dy - size)
        ..lineTo(c.dx + size, c.dy - size)
        ..lineTo(c.dx - size, c.dy + size)
        ..lineTo(c.dx + size, c.dy + size);
      canvas.drawPath(
        z,
        _stroke(Color.lerp(bone, glow, 0.35)!.withAlpha(alpha), 1.6),
      );
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

      // Ribs on the torso (shorter when curled up so the rings don't overlap)
      if (i > 2 && i < n * 0.72) {
        final ribLen = (4 + 24 * taper) * (1 - 0.55 * fx.fold);
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

    final lift = side > 0 ? fx.wing : 0.0; // one wing flaps on its own
    final fold = fx.fold * (1 - 0.6 * lift); // 1 = tucked against the body
    // a happy dragon flaps bigger; a sleeping one doesn't flap at all
    final flap =
        math.sin(t * 3.2) * 0.28 * (1 + 0.5 * happyOf()) * (1 - fx.fold) +
            lift * math.sin(t * 14) * 0.22 +
            fx.stretch * math.sin(t * 7) * 0.1;
    final spread = ui.lerpDouble(
        math.pi * 0.62 - fx.stretch * 0.1, math.pi * 0.93, fold)!;
    final armAngle = base + side * (spread + flap);
    final lenK = (1 + 0.25 * fx.stretch) * (1 - 0.5 * fold);
    final elbow =
        anchor + Offset(math.cos(armAngle), math.sin(armAngle)) * (52 * lenK);

    final fingerAngles = [-0.55, -0.05, 0.45];
    final fingerLens = [78.0, 92.0, 68.0];
    final tips = <Offset>[];
    for (int f = 0; f < 3; f++) {
      final ang = armAngle +
          side * fingerAngles[f] * (1 - 0.6 * fold) +
          side * flap * 0.6;
      tips.add(
          elbow + Offset(math.cos(ang), math.sin(ang)) * (fingerLens[f] * lenK));
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
    final burp = burpOf();
    final happy = happyOf();
    final fire = math.max(
      math.max(
        ((speedOf() - 2.8) / 6).clamp(0.0, 1.0).toDouble(),
        burp * 0.9,
      ),
      fx.yawn * 0.4, // a yawn lets out a little fire
    );
    final pulse = 0.75 + 0.25 * math.sin(t * 4);
    final headShake = headShakeOf();

    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(a);
    canvas.rotate(fx.look); // looking around while idle

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
      case _DragonState.feed:
        mouthOpen = 5.0; // mouth open, rushing to the food
        break;
      case _DragonState.eat:
        mouthOpen = 0.6 + math.sin(t * 22).abs() * 6.0; // chomp chomp
        break;
      case _DragonState.goSleep:
        mouthOpen = 1.0;
        break;
      case _DragonState.sleep:
        mouthOpen = 0.0;
        break;
      case _DragonState.wake:
        mouthOpen = 0.6 + fx.yawn * 11.0; // big yawn
        break;
      default:
        mouthOpen = (math.sin(t * 2.5) * 0.5 + 0.5) * 1.5 + fire * 3;
    }
    mouthOpen += burp * 5.0;

    canvas.drawLine(const Offset(8, 0), const Offset(34, 0), _stroke(bone, 1.2));
    final tooth = _stroke(bone, 1.5);
    for (double x = 14; x <= 32; x += 4) {
      final y = 3.2 - (x - 14) * 0.08;
      canvas.drawLine(Offset(x, y), Offset(x + 0.6, y + 2.5 + mouthOpen), tooth);
      canvas.drawLine(
          Offset(x, -y), Offset(x + 0.6, -y - 2.5 - mouthOpen), tooth);
    }

    // Eyes + nostrils (eyes grow larger & brighter when noticing, hungry or happy)
    final isNoticing = state == _DragonState.notice ||
        state == _DragonState.stalk ||
        state == _DragonState.feed;
    final eyeScale = (isNoticing ? 1.35 : 1.0) + happy * 0.15;
    final eyeAlpha =
        (isNoticing || happy > 0.3) ? 255 : (170 * pulse).round();

    for (final s in [-1.0, 1.0]) {
      final open = (s < 0 ? fx.eyeA : fx.eyeB).clamp(0.0, 1.0).toDouble();

      // eyelid: squash the eye vertically around its center
      canvas.save();
      canvas.translate(4, 6 * s);
      canvas.scale(1, math.max(0.1, open));
      canvas.translate(-4, -6 * s);

      _fill.color = Colors.black;
      _fill.maskFilter = null;
      canvas.drawCircle(Offset(4, 6 * s), 4.2 * eyeScale, _fill);
      canvas.drawCircle(
        Offset(4, 6 * s),
        6.5 * eyeScale,
        _blur(glow.withAlpha((eyeAlpha * open).round()), 5),
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
      canvas.restore();

      if (open < 0.25) {
        // closed eyelid line
        canvas.drawLine(
            Offset(0.5, 6 * s), Offset(8, 6 * s), _stroke(bone, 1.4));
      }

      _fill.color = Colors.black;
      canvas.drawCircle(Offset(29, 1.6 * s), 0.9, _fill);
    }

    // Brow ridge
    canvas.drawLine(const Offset(-2, -9), const Offset(12, -8), _stroke(bone, 1.4));
    canvas.drawLine(const Offset(-2, 9), const Offset(12, 8), _stroke(bone, 1.4));

    // Fire breath when moving fast, and a puff of fire after every meal
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