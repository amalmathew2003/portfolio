import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Loading screen: "AMAL MATHEW" drops in letter by letter behind a dragon
/// skeleton that assembles itself bone by bone while the number counts up.
/// At 100% the letters fill and glow, the dragon's eyes ignite, the wings
/// flare, and the dragon flies through the screen.
/// Black background, white only.
///
/// Usage:
/// NameLoadingScreen(
///   duration: Duration(seconds: 6),
///   onFinished: () {
///     Navigator.of(context).pushReplacement(
///       MaterialPageRoute(builder: (_) => const MyPortfolio()),
///     );
///   },
/// )
class NameLoadingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration duration;
  final String title;
  final String tagline;
  final Color color;

  /// Size of the dragon. 1.0 = fills the screen nicely, 0.7 = smaller.
  final double scale;

  /// Size of the name. 1.0 = fits the screen, 0.8 = smaller.
  final double nameScale;

  /// Vertical centre of the name / dragon as a fraction of the screen height
  /// (0 = top, 1 = bottom). Leave null for the automatic layout.
  final double? nameY;
  final double? dragonY;

  /// Font of the name. Must be declared in pubspec.yaml (see notes), e.g.
  /// 'Orbitron', 'Bebas Neue', 'Playfair Display'. null = default font.
  final String? nameFont;
  final FontWeight nameWeight;

  /// Easiest way to use any Google font (needs the google_fonts package):
  ///   nameStyle: GoogleFonts.orbitron(),
  ///   fontReady: GoogleFonts.pendingFonts([GoogleFonts.orbitron()]),
  /// fontReady makes the animation wait until the font has loaded.
  final TextStyle? nameStyle;
  final Future<void>? fontReady;

  const NameLoadingScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(seconds: 6),
    this.title = 'PORTFOLIO',
    this.tagline = 'FLUTTER DEVELOPER',
    this.color = const Color(0xFFFFFFFF),
    this.scale = 1.0,
    this.nameScale = 1.0,
    this.nameY,
    this.dragonY,
    this.nameFont,
    this.nameWeight = FontWeight.w700,
    this.nameStyle,
    this.fontReady,
  });

  @override
  State<NameLoadingScreen> createState() => _NameLoadingScreenState();
}

class _NameLoadingScreenState extends State<NameLoadingScreen>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  _NameDragonPainter? _painter;
  final math.Random _rng = math.Random(7);
  late final _Scene _scene;

  final ValueNotifier<double> _frame = ValueNotifier(0);
  final ValueNotifier<int> _pct = ValueNotifier(0);
  final ValueNotifier<List<String>> _log =
      ValueNotifier(<String>['> boot sequence initiated']);

  int _phase = 0; // 0 loading, 1 hold, 2 exit, 3 done
  double _phaseStart = 0;
  double _lastT = 0;
  int _lastBuilt = 0;
  bool _msgName = false;
  bool _msgWings = false;
  bool _msgEyes = false;
  bool _msgDone = false;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _scene = _Scene(_rng);
    _boot();
  }

  Future<void> _boot() async {
    final f = widget.fontReady;
    if (f != null) {
      try {
        await f.timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _painter = _NameDragonPainter(
        _scene,
        widget.color,
        widget.scale,
        widget.nameScale,
        widget.nameY,
        widget.dragonY,
        widget.nameFont,
        widget.nameWeight,
        widget.nameStyle,
        widget.tagline,
        _frame,
      );
    });
    _ticker = createTicker(_onTick)..start();
  }

  // Fake "real" loading: fast, stalls, fast again
  double _fake(double t) {
    t = t.clamp(0.0, 1.0).toDouble();
    const k = [
      [0.0, 0.0],
      [0.12, 0.10],
      [0.22, 0.14],
      [0.40, 0.46],
      [0.52, 0.50],
      [0.62, 0.52],
      [0.78, 0.88],
      [0.88, 0.92],
      [1.0, 1.0],
    ];
    for (int i = 1; i < k.length; i++) {
      if (t <= k[i][0]) {
        final u = (t - k[i - 1][0]) / (k[i][0] - k[i - 1][0]);
        return k[i - 1][1] + (k[i][1] - k[i - 1][1]) * u;
      }
    }
    return 1;
  }

  void _push(String msg) {
    final l = [..._log.value, msg];
    _log.value = l.length > 3 ? l.sublist(l.length - 3) : l;
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (t - _lastT).clamp(0.0, 0.05).toDouble();
    _lastT = t;
    _scene.time = t;

    final dur = widget.duration.inMilliseconds / 1000.0;
    if (_phase == 0) {
      _scene.progress = _fake(t / dur);
      if (_scene.progress >= 1) {
        _phase = 1;
        _phaseStart = t;
        _scene.burst(_rng);
      }
    } else if (_phase == 1) {
      if (t - _phaseStart > 1.2) {
        _phase = 2;
        _phaseStart = t;
        if (mounted) setState(() => _exiting = true);
      }
    } else if (_phase == 2) {
      _scene.exit = ((t - _phaseStart) / 0.85).clamp(0.0, 1.0).toDouble();
      if (_scene.exit >= 1) {
        _phase = 3;
        _ticker?.stop();
        widget.onFinished();
      }
    }

    _scene.step(dt, _rng);

    // status messages
    if (_scene.built != _lastBuilt) {
      _lastBuilt = _scene.built;
      _push('> vertebra ${_scene.built}/${_Scene.n} locked');
    }
    if (!_msgName && _scene.letBuilt >= _Scene.nameN) {
      _msgName = true;
      _push('> identity: AMAL MATHEW');
    }
    if (!_msgWings && _scene.progress > 0.68) {
      _msgWings = true;
      _push('> unfolding wings');
    }
    if (!_msgEyes && _scene.progress > 0.97) {
      _msgEyes = true;
      _push('> igniting eyes');
    }
    if (!_msgDone && _scene.progress >= 1) {
      _msgDone = true;
      _push('> dragon awake');
    }

    final pct = (_scene.progress * 100).floor();
    if (pct != _pct.value) _pct.value = pct;
    _frame.value = t;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _frame.dispose();
    _pct.dispose();
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material gives every Text a proper default style (no yellow underline).
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _painter),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _exiting ? 0 : 1,
              duration: const Duration(milliseconds: 350),
              child: _Overlay(
                pct: _pct,
                log: _log,
                title: widget.title,
                color: widget.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================= text on the screen
const List<String> _kMonoFallback = ['Courier New', 'Consolas', 'Menlo'];

class _Overlay extends StatelessWidget {
  final ValueNotifier<int> pct;
  final ValueNotifier<List<String>> log;
  final String title;
  final Color color;

  const _Overlay({
    required this.pct,
    required this.log,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final mono = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: _kMonoFallback,
      decoration: TextDecoration.none,
      color: color.withAlpha(170),
    );
    final h = MediaQuery.sizeOf(context).height;
    final fs = (h * 0.2).clamp(54.0, 150.0).toDouble();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(28, 22, 28, 22),
      child: Stack(
        children: [
          // top left: title
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: mono.copyWith(
                    fontSize: 12,
                    letterSpacing: 8,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 36, height: 1, color: color.withAlpha(120)),
              ],
            ),
          ),
          // top right: status
          Align(
            alignment: Alignment.topRight,
            child: ValueListenableBuilder<int>(
              valueListenable: pct,
              builder: (context, p, _) => Text(
                p >= 100 ? '● AWAKE' : '● SUMMONING',
                style: mono.copyWith(fontSize: 11, letterSpacing: 3),
              ),
            ),
          ),
          // bottom left: big outlined number
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 34),
              child: ValueListenableBuilder<int>(
                valueListenable: pct,
                builder: (context, p, _) {
                  final done = p >= 100;
                  final style = TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: _kMonoFallback,
                    fontSize: fs,
                    height: 0.9,
                    letterSpacing: -3,
                    fontWeight: FontWeight.w200,
                    decoration: TextDecoration.none,
                    color: done ? color : null,
                    foreground: done
                        ? null
                        : (Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 1.2
                          ..color = color.withAlpha(230)),
                  );
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.toString().padLeft(2, '0'), style: style),
                      Padding(
                        padding: EdgeInsets.only(top: fs * 0.12, left: 4),
                        child: Text(
                          '%',
                          style: mono.copyWith(
                            fontSize: fs * 0.22,
                            color: color.withAlpha(200),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // bottom right: log
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 34),
              child: ValueListenableBuilder<List<String>>(
                valueListenable: log,
                builder: (context, l, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < l.length; i++)
                      Text(
                        l[i],
                        style: mono.copyWith(
                          fontSize: 11,
                          color: color.withAlpha(
                            i == l.length - 1
                                ? 230
                                : (110 - (l.length - 1 - i) * 35)
                                    .clamp(30, 255)
                                    .toInt(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================== the scene
class _Spark {
  Offset pos;
  Offset vel;
  double life;
  _Spark(this.pos, this.vel, this.life);
}

class _Dust {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double alpha;
  _Dust(this.x, this.y, this.speed, this.size, this.alpha);
}

/// All animated data. Units are "dragon units": the whole spine is 559 long.
class _Scene {
  static const int n = 44; // number of vertebrae, index 0 = tail, n-1 = head
  static const double len = 13.0 * (n - 1);

  /// The name, without the space: AMAL (0-3) + MATHEW (4-9).
  static const String letters = 'AMALMATHEW';
  static const int nameN = 10;

  double time = 0;
  double progress = 0;
  double exit = 0;
  double flare = 0;
  int built = 0;
  int letBuilt = 0;
  double tagStart = -1; // when the tagline starts decoding (right after the name)

  // dragon
  final List<double> spawn = List.filled(n, -1);
  final List<double> ease = List.filled(n, 0);
  final List<Offset> offs = [];
  final List<Offset> base = List.filled(n, Offset.zero);
  final List<Offset> pts = List.filled(n, Offset.zero);
  final List<double> heading = List.filled(n, 0);
  final List<_Spark> sparks = [];
  final List<_Dust> dust = [];

  // name letters
  final List<double> letSpawn = List.filled(nameN, -1);
  final List<double> letEase = List.filled(nameN, 0);
  final List<double> letPop = List.filled(nameN, 0);
  final List<Offset> letOffs = [];

  _Scene(math.Random rng) {
    for (int i = 0; i < n; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final d = 90 + rng.nextDouble() * 170;
      offs.add(Offset(math.cos(a) * d, math.sin(a) * d));
    }
    for (int i = 0; i < nameN; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final d = 220 + rng.nextDouble() * 320;
      letOffs.add(Offset(math.cos(a) * d, math.sin(a) * d));
    }
    for (int i = 0; i < 70; i++) {
      dust.add(_Dust(
        rng.nextDouble(),
        rng.nextDouble(),
        0.01 + rng.nextDouble() * 0.03,
        0.6 + rng.nextDouble() * 0.9,
        0.10 + rng.nextDouble() * 0.25,
      ));
    }
  }

  // The spine is a gentle S-curve that ripples like it is swimming.
  Offset spine(double u) {
    final x = -len / 2 + len * u;
    final amp = 52 * (0.35 + 0.65 * (1 - u));
    final y = amp * math.sin(u * 6.6 - time * 1.5) + 10 * math.sin(time * 0.6);
    return Offset(x, y);
  }

  void burst(math.Random rng) {
    final p = pts[n - 1];
    final a = heading[n - 1];
    for (int j = 0; j < 30; j++) {
      final ang = a + (rng.nextDouble() - 0.5) * 0.9;
      final v = 120 + rng.nextDouble() * 260;
      sparks.add(_Spark(
        p + Offset(math.cos(a), math.sin(a)) * 40,
        Offset(math.cos(ang) * v, math.sin(ang) * v),
        1,
      ));
    }
  }

  void step(double dt, math.Random rng) {
    // new bones snap into place as the loading moves on
    final want = progress / 0.92 * n;
    while (built < n && want >= built) {
      spawn[built] = time;
      final p = spine(built / (n - 1));
      for (int j = 0; j < 3; j++) {
        final a = rng.nextDouble() * math.pi * 2;
        final v = 40 + rng.nextDouble() * 80;
        sparks.add(_Spark(p, Offset(math.cos(a) * v, math.sin(a) * v), 1));
      }
      built++;
    }

    // name letters drop in a little ahead of the dragon
    final wantL = progress / 0.86 * nameN;
    while (letBuilt < nameN && wantL >= letBuilt) {
      letSpawn[letBuilt] = time;
      letBuilt++;
    }
    for (int i = 0; i < nameN; i++) {
      double e = 0;
      double pop = 0;
      if (letSpawn[i] >= 0) {
        final since = time - letSpawn[i];
        final l = (since / 0.55).clamp(0.0, 1.0).toDouble();
        e = 1 - math.pow(1 - l, 3).toDouble();
        final land = since - 1.1; // locks onto the real letter
        if (land > 0) pop = math.exp(-land * 6);
      }
      letEase[i] = e;
      letPop[i] = pop;
    }

    // tagline starts as soon as the last letter of the name has appeared
    if (letBuilt >= nameN && tagStart < 0) tagStart = time + 0.35;

    final target = progress >= 1 ? 1.0 : 0.0;
    flare += (target - flare) * math.min(1.0, dt * 5);

    for (final sp in sparks) {
      sp.pos += sp.vel * dt;
      sp.vel = sp.vel * (1 - 1.5 * dt);
      sp.life -= dt * 1.5;
    }
    sparks.removeWhere((sp) => sp.life <= 0);
    if (sparks.length > 140) sparks.removeRange(0, sparks.length - 140);

    for (int i = 0; i < n; i++) {
      base[i] = spine(i / (n - 1));
    }
    for (int i = 0; i < n; i++) {
      final d = base[math.min(i + 1, n - 1)] - base[math.max(i - 1, 0)];
      heading[i] = math.atan2(d.dy, d.dx);

      double e = 0;
      if (spawn[i] >= 0) {
        final l = ((time - spawn[i]) / 0.45).clamp(0.0, 1.0).toDouble();
        e = 1 - math.pow(1 - l, 3).toDouble();
      }
      ease[i] = e;
      pts[i] = base[i] + offs[i] * (1 - e);
    }
  }
}

double _smooth(double x) {
  x = x.clamp(0.0, 1.0).toDouble();
  return x * x * (3 - 2 * x);
}

// ================================================================= the painter
class _FontSpec {
  final String? family;
  final FontWeight weight;
  final FontStyle fontStyle;
  final List<String>? fallback;
  const _FontSpec(
    this.family,
    this.weight, [
    this.fontStyle = FontStyle.normal,
    this.fallback,
  ]);
}

class _NameDragonPainter extends CustomPainter {
  final _Scene s;
  final Color color;
  final double scaleMul;
  final double nameMul;
  final double? nameY;
  final double? dragonY;
  final String? nameFont;
  final FontWeight nameWeight;
  final TextStyle? nameStyle;
  final String tagline;

  double fade = 1;
  final Paint _s = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _f = Paint()..style = PaintingStyle.fill;

  // [fontIndex][letter]; the LAST font index is the final font.
  late final List<List<TextPainter>> _outline;
  late final List<List<TextPainter>> _fill;
  late final List<List<TextPainter>> _glow;

  /// Random characters each letter cycles through before it locks.
  static const String _pool =
      'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#@\$%&*<>/{}[]=+?';
  late final List<TextPainter> _scr;

  /// How long (seconds) each letter scrambles after it appears.
  static const double _shuffleTime = 1.1;
  // tagline (same font + decode effect as the name)
  late final List<TextPainter> _tagFill;
  late final List<TextPainter> _tagGlow;
  late final List<TextPainter> _scrFill;
  late final List<double> _tagPos;
  late final double _tagTotal;
  late final List<Offset> _slotsLand;
  late final List<Offset> _slotsPort;
  late final double _totalLand;
  late final double _totalPort;

  _NameDragonPainter(
    this.s,
    this.color,
    this.scaleMul,
    this.nameMul,
    this.nameY,
    this.dragonY,
    this.nameFont,
    this.nameWeight,
    this.nameStyle,
    this.tagline,
    Listenable repaint,
  ) : super(repaint: repaint) {
    TextStyle style(_FontSpec sp, {Paint? fg, Color? c}) => TextStyle(
          fontFamily: sp.family,
          fontFamilyFallback: sp.fallback,
          fontStyle: sp.fontStyle,
          fontSize: 100,
          height: 1,
          letterSpacing: 6,
          fontWeight: sp.weight,
          decoration: TextDecoration.none,
          color: fg == null ? c : null,
          foreground: fg,
        );

    TextPainter mk(String ch, TextStyle st) => TextPainter(
          text: TextSpan(text: ch, style: st),
          textDirection: TextDirection.ltr,
        )..layout();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color;
    final blur = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final specs = <_FontSpec>[
      // final font: a TextStyle (e.g. GoogleFonts.orbitron()) wins over nameFont
      _FontSpec(
        nameStyle?.fontFamily ?? nameFont,
        nameStyle?.fontWeight ?? nameWeight,
        nameStyle?.fontStyle ?? FontStyle.normal,
        nameStyle?.fontFamilyFallback,
      ),
    ];
    _scr = [
      for (int i = 0; i < _pool.length; i++)
        mk(_pool[i], style(const _FontSpec('monospace', FontWeight.w300),
            fg: stroke)),
    ];
    _outline = [
      for (final sp in specs)
        [
          for (int i = 0; i < _Scene.nameN; i++)
            mk(_Scene.letters[i], style(sp, fg: stroke)),
        ],
    ];
    _fill = [
      for (final sp in specs)
        [
          for (int i = 0; i < _Scene.nameN; i++)
            mk(_Scene.letters[i], style(sp, c: color)),
        ],
    ];
    _glow = [
      for (final sp in specs)
        [
          for (int i = 0; i < _Scene.nameN; i++)
            mk(_Scene.letters[i], style(sp, fg: blur)),
        ],
    ];
    _scrFill = [
      for (int i = 0; i < _pool.length; i++)
        mk(_pool[i], style(const _FontSpec('monospace', FontWeight.w400),
            c: color)),
    ];
    _tagFill = [
      for (int i = 0; i < tagline.length; i++) mk(tagline[i], style(specs[0], c: color)),
    ];
    _tagGlow = [
      for (int i = 0; i < tagline.length; i++) mk(tagline[i], style(specs[0], fg: blur)),
    ];
    {
      const track = 22.0; // extra spacing between tagline letters
      final tw = [for (final t in _tagFill) t.width + track];
      final tt = tw.fold<double>(0, (a, b) => a + b);
      final pos = <double>[];
      double tx = -tt / 2;
      for (int i = 0; i < tw.length; i++) {
        pos.add(tx + tw[i] / 2);
        tx += tw[i];
      }
      _tagPos = pos;
      _tagTotal = tt;
    }

    // lay the letters out by their real widths (works with any font)
    final wd = [for (final t in _outline.last) t.width];
    double sum(int a, int b) {
      double t = 0;
      for (int i = a; i < b; i++) {
        t += wd[i];
      }
      return t;
    }

    const gap = 50.0;
    final total = sum(0, 10) + gap;
    final land = <Offset>[];
    double x = -total / 2;
    for (int i = 0; i < _Scene.nameN; i++) {
      if (i == 4) x += gap;
      land.add(Offset(x + wd[i] / 2, 0));
      x += wd[i];
    }
    final port = <Offset>[];
    final w1 = sum(0, 4);
    final w2 = sum(4, 10);
    double x1 = -w1 / 2;
    double x2 = -w2 / 2;
    for (int i = 0; i < _Scene.nameN; i++) {
      if (i < 4) {
        port.add(Offset(x1 + wd[i] / 2, -62));
        x1 += wd[i];
      } else {
        port.add(Offset(x2 + wd[i] / 2, 62));
        x2 += wd[i];
      }
    }
    _slotsLand = land;
    _slotsPort = port;
    _totalLand = total;
    _totalPort = math.max(w1, w2);
  }

  Color col(double a) =>
      color.withAlpha((a.clamp(0.0, 1.0).toDouble() * fade * 255).round());

  void _line(Canvas c, Offset a, Offset b, double w, double alpha) {
    _s.strokeWidth = w;
    _s.color = col(alpha);
    c.drawLine(a, b, _s);
  }

  void _stroke(Canvas c, Path p, double w, double alpha) {
    _s.strokeWidth = w;
    _s.color = col(alpha);
    c.drawPath(p, _s);
  }

  void _dot(Canvas c, Offset p, double r, double alpha) {
    _f.color = col(alpha);
    c.drawCircle(p, r, _f);
  }

  void _ring(Canvas c, Offset p, double r, double w, double alpha) {
    _s.strokeWidth = w;
    _s.color = col(alpha);
    c.drawCircle(p, r, _s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    fade = 1 - _smooth((s.exit - 0.1) / 0.8);
    final w = size.width;
    final h = size.height;
    final portrait = h > w * 1.15;
    final longSide = portrait ? h : w;
    final shortSide = portrait ? w : h;
    // the dragon lives in the lower part of the screen, below the name
    final fit = portrait ? 0.62 : 0.56;
    final k = math.min(longSide * 0.84 / 650, shortSide * 0.92 / 430) *
        fit *
        scaleMul;
    final dragonCy = h * (dragonY ?? (portrait ? 0.64 : 0.68));

    _drawDust(canvas, size);
    _drawSpotlight(canvas, size, portrait);
    _drawRing(canvas, size);
    _drawName(canvas, size, portrait);

    canvas.save();
    canvas.translate(w / 2, dragonCy);
    if (portrait) canvas.rotate(-math.pi / 2); // dragon stands up on phones
    canvas.scale(k);

    // camera flies toward the head at the end
    if (s.exit > 0) {
      final hd = s.pts[_Scene.n - 1];
      final zs = 1 + s.exit * s.exit * 3.2;
      canvas.translate(hd.dx, hd.dy);
      canvas.scale(zs);
      canvas.translate(-hd.dx, -hd.dy);
    }

    for (final sp in s.sparks) {
      _dot(canvas, sp.pos, 0.6 + 1.2 * sp.life, 0.9 * sp.life);
    }
    _drawWing(canvas, -1);
    _drawWing(canvas, 1);
    _drawBody(canvas);
    _drawHead(canvas);

    canvas.restore();

    _drawHairline(canvas, size);
    _drawBrackets(canvas, size);

    // white flash while the dragon flies through
    if (s.exit > 0) {
      final e = s.exit;
      final fl = e < 0.3 ? e / 0.3 : 1 - (e - 0.3) / 0.7;
      _f.color = Colors.white
          .withAlpha((fl.clamp(0.0, 1.0).toDouble() * 0.9 * 255).round());
      canvas.drawRect(Offset.zero & size, _f);
    }
  }

  // soft light behind the name: grows as the letters appear, brighter at 100%
  void _drawSpotlight(Canvas canvas, Size size, bool portrait) {
    final cy = size.height * (nameY ?? (portrait ? 0.2 : 0.27));
    final amt = (s.letBuilt / _Scene.nameN) * 0.07 + s.flare * 0.10;
    if (amt <= 0.003) return;
    final c = Offset(size.width / 2, cy);
    final r = size.width * 0.7;
    _f.shader = RadialGradient(colors: [col(amt), col(0)])
        .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawRect(Offset.zero & size, _f);
    _f.shader = null;
  }

  // ------------------------------------------------------------- the name
  Offset _slot(int j, bool portrait) =>
      portrait ? _slotsPort[j] : _slotsLand[j];

  void _drawName(Canvas canvas, Size size, bool portrait) {
    final w = size.width;
    final h = size.height;
    final double k = portrait
        ? math.min(w * 0.86 / _totalPort, h * 0.2 / 224) * nameMul
        : math.min(w * 0.88 / _totalLand, h * 0.2 / 100) * nameMul;
    final nameCy = h * (nameY ?? (portrait ? 0.2 : 0.27));

    canvas.save();
    canvas.translate(w / 2, nameCy);
    if (s.exit > 0) {
      final zs = 1 + s.exit * s.exit * 2.5;
      canvas.scale(zs);
    }
    canvas.scale(k);

    // a band of light sweeps across the name once it is loaded
    final total = portrait ? _totalPort : _totalLand;
    final sweep = s.flare > 0.5
        ? -total / 2 - 150 + ((s.time * 260) % (total + 500))
        : -99999.0;

    for (int j = 0; j < _Scene.nameN; j++) {
      final e = s.letEase[j];
      if (e <= 0.01) continue;
      final pop = s.letPop[j];

      final wave = Offset(
        0,
        math.sin(s.time * 1.6 + j * 0.6) * 5 * (1 - s.flare * 0.7),
      );
      final p = _slot(j, portrait) + wave + s.letOffs[j] * (1 - e);

      final dd = (p.dx - sweep) / 90;
      final shine = s.flare * math.exp(-dd * dd);

      // decode effect: random characters flick by, then lock to the real letter
      final since = s.time - s.letSpawn[j];
      final scrambling = since < _shuffleTime;
      final hsh = (since * 18).floor() * 31 + j * 17 + j * j * 5;
      final o = scrambling ? _scr[hsh % _pool.length] : _outline[0][j];
      final bounds = Rect.fromLTWH(-50, -50, o.width + 100, o.height + 100);

      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate((1 - e) * 0.9);
      canvas.scale((0.6 + 0.4 * e) * (1 + 0.2 * pop));

      final glowA = scrambling
          ? 0.0
          : e *
              (s.flare * (0.35 + 0.25 * math.sin(s.time * 3 - j * 0.5)) +
                  pop * 0.6 +
                  shine * 0.9);
      final outA = e * (0.5 + 0.5 * s.flare) + pop * 0.4 + shine * 0.4;

      canvas.translate(-o.width / 2, -o.height / 2);
      if (glowA > 0.01) {
        canvas.saveLayer(bounds, Paint()..color = col(glowA));
        _glow[0][j].paint(canvas, Offset.zero);
        canvas.restore();
      }
      if (s.flare > 0.01 && !scrambling) {
        canvas.saveLayer(
            bounds, Paint()..color = col(e * s.flare * 0.28 + shine * 0.5));
        _fill[0][j].paint(canvas, Offset.zero);
        canvas.restore();
      }
      canvas.saveLayer(bounds, Paint()..color = col(outA));
      o.paint(canvas, Offset.zero);
      canvas.restore();

      // glitch echo: a ghost copy slides off the letter when it locks
      if (pop > 0.05 && !scrambling) {
        canvas.save();
        canvas.translate(pop * 12, 0);
        canvas.saveLayer(bounds, Paint()..color = col(pop * 0.45));
        o.paint(canvas, Offset.zero);
        canvas.restore();
        canvas.restore();
      }

      canvas.restore();
    }
    canvas.restore();

    // tagline: same font + decode effect, appears right after the name
    if (s.tagStart >= 0 && s.time >= s.tagStart) {
      final ts = math.min(k * 0.28, w * 0.86 / _tagTotal);
      final y = nameCy + ((portrait ? 62 : 0) + 50 + 34) * k;
      canvas.save();
      canvas.translate(w / 2, y);
      canvas.scale(ts);
      for (int i = 0; i < _tagFill.length; i++) {
        if (tagline[i] == ' ') continue;
        final since = s.time - s.tagStart - i * 0.035;
        if (since < 0) continue;
        final scr = since < 0.7;
        final hsh = (since * 18).floor() * 29 + i * 13 + i * i * 3;
        final tp = scr ? _scrFill[hsh % _pool.length] : _tagFill[i];
        final pop = scr ? 0.0 : math.exp(-(since - 0.7) * 6);
        final bounds =
            Rect.fromLTWH(-50, -50, tp.width + 100, tp.height + 100);

        canvas.save();
        canvas.translate(_tagPos[i], 0);
        canvas.scale(1 + 0.25 * pop);
        canvas.translate(-tp.width / 2, -tp.height / 2);

        // glow: flash when a letter locks, travelling pulse at 100%
        final gA = scr
            ? 0.0
            : pop * 0.8 +
                s.flare * (0.25 + 0.2 * math.sin(s.time * 3 - i * 0.4));
        if (gA > 0.02) {
          canvas.saveLayer(bounds, Paint()..color = col(gA));
          _tagGlow[i].paint(canvas, Offset.zero);
          canvas.restore();
        }
        canvas.saveLayer(
          bounds,
          Paint()..color = col(scr ? 0.6 : 0.72 + 0.28 * s.flare),
        );
        tp.paint(canvas, Offset.zero);
        canvas.restore();
        canvas.restore();
      }

      // thin line under the tagline that grows out from the centre, with a
      // little light that keeps sweeping along it
      final grow = _smooth((s.time - s.tagStart) / 0.9);
      if (grow > 0.01) {
        final half = _tagTotal / 2 * grow;
        const ly = 78.0;
        _line(canvas, Offset(-half, ly), Offset(half, ly), 3, 0.22);
        _dot(canvas, Offset(-half, ly), 3.5, 0.6);
        _dot(canvas, Offset(half, ly), 3.5, 0.6);
        if (grow > 0.95) {
          final u = (s.time * 0.5) % 1.0;
          final cx = -half + 2 * half * u;
          final a0 = math.max(-half, cx - 70);
          final a1 = math.min(half, cx + 70);
          _line(canvas, Offset(a0, ly), Offset(a1, ly), 4, 0.9);
        }
      }
      canvas.restore();
    }
  }

  // -------------------------------------------- circular progress + frame
  void _drawRing(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.44;
    const ticks = 120;
    final zoom = 1 + s.exit * s.exit * 2.0;

    for (int i = 0; i < ticks; i++) {
      final u = i / ticks;
      final a = -math.pi / 2 + u * math.pi * 2;
      final long = i % 10 == 0;
      final lit = u <= s.progress;
      final r0 = r * zoom;
      final r1 = (r + (long ? 11 : 5)) * zoom;
      final dir = Offset(math.cos(a), math.sin(a));
      _line(
        canvas,
        c + dir * r0,
        c + dir * r1,
        long ? 1.4 : 1.0,
        lit ? (long ? 0.75 : 0.45) : 0.10,
      );
    }

    // inner ring: tiny dashes drifting one way, bright arcs the other way
    final r2 = r * 0.93 * zoom;
    final dashRect = Rect.fromCircle(center: c, radius: r2);
    _s.strokeWidth = 1.0;
    _s.color = col(0.12 + s.flare * 0.12);
    for (int i = 0; i < 48; i++) {
      final a = i / 48 * math.pi * 2 - s.time * 0.25;
      canvas.drawArc(dashRect, a, 0.05, false, _s);
    }
    final arcRect = Rect.fromCircle(center: c, radius: r * 0.965 * zoom);
    _s.strokeWidth = 1.6;
    _s.color = col(0.18 + s.flare * 0.3);
    for (int k = 0; k < 3; k++) {
      final a = s.time * 0.6 + k * math.pi * 2 / 3;
      canvas.drawArc(arcRect, a, 0.45, false, _s);
    }

    // a little satellite that orbits the ring
    final oa = s.time * 0.8;
    final op = c + Offset(math.cos(oa), math.sin(oa)) * (r - 14) * zoom;
    _dot(canvas, op, 2.2, 0.7);
    _ring(canvas, op, 5, 0.8, 0.25);
  }

  void _drawBrackets(Canvas canvas, Size size) {
    const inset = 14.0;
    const len = 20.0;
    final w = size.width;
    final h = size.height;
    const a = 0.5;
    // top-left
    _line(canvas, const Offset(inset, inset),
        const Offset(inset + len, inset), 1.2, a);
    _line(canvas, const Offset(inset, inset),
        const Offset(inset, inset + len), 1.2, a);
    // top-right
    _line(canvas, Offset(w - inset, inset), Offset(w - inset - len, inset),
        1.2, a);
    _line(canvas, Offset(w - inset, inset), Offset(w - inset, inset + len),
        1.2, a);
    // bottom-left
    _line(canvas, Offset(inset, h - inset), Offset(inset + len, h - inset),
        1.2, a);
    _line(canvas, Offset(inset, h - inset), Offset(inset, h - inset - len),
        1.2, a);
    // bottom-right
    _line(canvas, Offset(w - inset, h - inset),
        Offset(w - inset - len, h - inset), 1.2, a);
    _line(canvas, Offset(w - inset, h - inset),
        Offset(w - inset, h - inset - len), 1.2, a);
  }

  void _drawDust(Canvas canvas, Size size) {
    for (final d in s.dust) {
      final yy = (((d.y - s.time * d.speed) % 1.0) + 1.0) % 1.0;
      _f.color = col(d.alpha);
      canvas.drawCircle(
        Offset(d.x * size.width, yy * size.height),
        d.size,
        _f,
      );
    }
  }

  void _drawHairline(Canvas canvas, Size size) {
    const pad = 28.0;
    final y = size.height - 24;
    const x0 = pad;
    final x1 = size.width - pad;

    _line(canvas, Offset(x0, y), Offset(x1, y), 1, 0.16);
    for (int i = 0; i <= 10; i++) {
      final x = x0 + (x1 - x0) * i / 10;
      _line(canvas, Offset(x, y - 3), Offset(x, y + 3), 1, 0.28);
    }
    final px = x0 + (x1 - x0) * s.progress;
    _line(canvas, Offset(x0, y), Offset(px, y), 2, 0.95);
    _dot(canvas, Offset(px, y), 3.2, 1);
  }

  // ------------------------------------------------------------------ wings
  Offset _scallop(Offset a, Offset b, Offset toward) {
    final mid = Offset.lerp(a, b, 0.5)!;
    return mid + (toward - mid) * 0.28;
  }

  void _drawWing(Canvas canvas, double side) {
    const idx = 33;
    final wp = _smooth((s.progress - 0.68) / 0.22);
    final w = wp * s.ease[idx];
    if (w <= 0.01) return;

    final anchor = s.pts[idx];
    final back = s.pts[idx - 6];
    final base = s.heading[idx];
    final flare = s.flare;

    final flap = math.sin(s.time * 2.2) * 0.14 * (1 + flare * 1.4);
    final armAngle = base + side * (math.pi * 0.60 + flap + flare * 0.12);
    final elbow = anchor +
        Offset(math.cos(armAngle), math.sin(armAngle)) * (58 * w);

    const fAng = [-0.55, -0.05, 0.45];
    const fLen = [88.0, 104.0, 76.0];
    final tips = <Offset>[];
    for (int f = 0; f < 3; f++) {
      final ang = armAngle + side * fAng[f] * (1 + flare * 0.15) + side * flap * 0.6;
      tips.add(elbow +
          Offset(math.cos(ang), math.sin(ang)) *
              (fLen[f] * w * (1 + flare * 0.12)));
    }

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

    _f.color = col(0.06 * w + flare * 0.05);
    canvas.drawPath(membrane, _f);
    _stroke(canvas, membrane, 1.0, 0.55 * w);

    // veins
    _line(canvas, elbow, Offset.lerp(tips[0], tips[1], 0.5)!, 0.8, 0.25 * w);
    _line(canvas, elbow, Offset.lerp(tips[1], tips[2], 0.5)!, 0.8, 0.25 * w);
    _line(canvas, anchor, Offset.lerp(tips[2], back, 0.5)!, 0.8, 0.25 * w);

    // bones
    _line(canvas, anchor, elbow, 2.4, w);
    for (final tip in tips) {
      _line(canvas, elbow, tip, 1.6, w);
      _dot(canvas, tip, 1.8, w);
    }
    _dot(canvas, elbow, 2.8, w);
  }

  // ------------------------------------------------------------------- body
  void _drawBody(Canvas canvas) {
    const n = _Scene.n;

    // spine line
    for (int i = 0; i < n - 1; i++) {
      final e = math.min(s.ease[i], s.ease[i + 1]);
      if (e > 0.01) _line(canvas, s.pts[i], s.pts[i + 1], 1.2, 0.45 * e);
    }

    // vertebrae, spikes, ribs (head is drawn separately)
    for (int i = 0; i < n - 1; i++) {
      final e = s.ease[i];
      if (e <= 0.01) continue;

      final p = s.pts[i];
      final a = s.heading[i];
      final u = i / (n - 1);
      final tau = math.pow(u, 0.7).toDouble();
      final tx = math.cos(a);
      final ty = math.sin(a);
      final nx = -ty;
      final ny = tx;
      final al = (0.5 + 0.5 * u) * e;

      // dorsal spike
      final sl = 4 + 10 * tau;
      final spike = Path()
        ..moveTo(p.dx + tx * 2.5, p.dy + ty * 2.5)
        ..lineTo(p.dx + nx * 1.8, p.dy + ny * 1.8)
        ..lineTo(p.dx - tx * sl, p.dy - ty * sl)
        ..lineTo(p.dx - nx * 1.8, p.dy - ny * 1.8)
        ..close();
      _f.color = col(0.4 * al);
      canvas.drawPath(spike, _f);

      // vertebra
      _dot(canvas, p, (1.4 + 3.4 * tau) * (0.6 + 0.4 * e), al);

      if (u > 0.34 && u < 0.9) {
        // ribs
        final rl = 5 + 30 * math.sin(((u - 0.34) / 0.56) * math.pi);
        for (final sd in const [-1.0, 1.0]) {
          final end = Offset(
            p.dx + nx * sd * rl - tx * rl * 0.5,
            p.dy + ny * sd * rl - ty * rl * 0.5,
          );
          final ctrl = Offset(
            p.dx + nx * sd * rl * 0.95 + tx * rl * 0.12,
            p.dy + ny * sd * rl * 0.95 + ty * rl * 0.12,
          );
          final rib = Path()
            ..moveTo(p.dx, p.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
          _stroke(canvas, rib, 1.1 + 1.5 * tau, al);
          _dot(canvas, end, 1.0, 0.8 * e);
        }
      } else if (u <= 0.34 && i.isEven) {
        // small side spikes on the tail
        for (final sd in const [-1.0, 1.0]) {
          _line(
            canvas,
            p,
            Offset(p.dx + nx * sd * 5 - tx * 3, p.dy + ny * sd * 5 - ty * 3),
            1.1,
            al,
          );
        }
      }
    }

    // tail blade
    final e0 = s.ease[0];
    if (e0 > 0.01) {
      final p = s.pts[0];
      final a = s.heading[0];
      final t = Offset(math.cos(a), math.sin(a));
      final nn = Offset(-math.sin(a), math.cos(a));
      final tip = p - t * 34;
      final l = p - t * 9 + nn * 12;
      final r = p - t * 9 - nn * 12;
      final blade = Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(l.dx, l.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(r.dx, r.dy)
        ..close();
      _f.color = col(0.10 * e0);
      canvas.drawPath(blade, _f);
      _stroke(canvas, blade, 1.2, 0.7 * e0);
      _line(canvas, p, tip, 1, 0.5 * e0);
    }
  }

  // ------------------------------------------------------------------- head
  void _drawHead(Canvas canvas) {
    final e = s.ease[_Scene.n - 1];
    if (e <= 0.01) return;

    final p = s.pts[_Scene.n - 1];
    final a = s.heading[_Scene.n - 1];
    final t = s.time;

    // eyes ignite at the very end
    var eg = _smooth((s.progress - 0.985) / 0.015);
    if (s.progress >= 1) eg *= 0.88 + 0.12 * math.sin(t * 14);
    final open = 0.8 + 0.8 * math.sin(t * 2) + s.flare * 3.5;

    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(a);
    canvas.scale(1.25 * (0.7 + 0.3 * e));

    // soft glow around the head when the eyes ignite
    if (eg > 0.01) {
      canvas.drawCircle(
        const Offset(10, 0),
        24,
        Paint()
          ..color = col(0.35 * eg)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // whiskers
    for (final sd in const [-1.0, 1.0]) {
      final w1 = math.sin(t * 4) * 4;
      final w2 = math.sin(t * 3 + 1) * 5;
      final wh = Path()
        ..moveTo(24, 4 * sd)
        ..quadraticBezierTo(38, 16 * sd + w1 * sd, 14, 28 * sd + w2 * sd);
      _stroke(canvas, wh, 0.9, 0.55 * e);
    }

    // horns
    for (final sd in const [-1.0, 1.0]) {
      final horn = Path()
        ..moveTo(-4, 9 * sd)
        ..quadraticBezierTo(-18, 20 * sd, -38, 13 * sd);
      _stroke(canvas, horn, 2.4, 0.9 * e);
      _dot(canvas, Offset(-38, 13 * sd), 1.8, 0.4 * e + 0.6 * eg);
    }

    // skull (black fill hides the bones behind it)
    final skull = Path()
      ..moveTo(-12, 0)
      ..cubicTo(-12, -13, 8, -13, 24, -5)
      ..lineTo(34, -3)
      ..lineTo(34, 3)
      ..lineTo(24, 5)
      ..cubicTo(8, 13, -12, 13, -12, 0)
      ..close();
    _f.color = Colors.black.withAlpha((e * fade * 255).round());
    canvas.drawPath(skull, _f);
    _stroke(canvas, skull, 1.8, e);

    // crest diamond
    final crest = Path()
      ..moveTo(-7, 0)
      ..lineTo(0, -3)
      ..lineTo(8, 0)
      ..lineTo(0, 3)
      ..close();
    _f.color = col(0.55 * e);
    canvas.drawPath(crest, _f);

    // mouth + teeth
    _line(canvas, const Offset(8, 0), const Offset(34, 0), 1.1, 0.8 * e);
    for (double x = 14; x <= 32; x += 4) {
      final y = 3.2 - (x - 14) * 0.08;
      _line(canvas, Offset(x, y), Offset(x + 0.6, y + 2.5 + open), 1.3, 0.8 * e);
      _line(canvas, Offset(x, -y), Offset(x + 0.6, -y - 2.5 - open), 1.3, 0.8 * e);
    }

    // eyes
    for (final sd in const [-1.0, 1.0]) {
      final c = Offset(4.5, 6 * sd);
      _f.color = Colors.black.withAlpha((e * fade * 255).round());
      canvas.drawCircle(c, 4.2, _f);
      _ring(canvas, c, 4.2, 0.9, 0.6 * e);
      if (eg > 0.01) {
        _dot(canvas, c, 2.4 * eg + 0.4, eg);
        _ring(canvas, c, 7 + 2 * math.sin(t * 6), 0.8, 0.45 * eg);
      }
      _dot(canvas, Offset(29, 1.6 * sd), 0.9, 0.5 * e);
    }

    // brow ridge
    _line(canvas, const Offset(-2, -9), const Offset(12, -8), 1.3, 0.8 * e);
    _line(canvas, const Offset(-2, 9), const Offset(12, 8), 1.3, 0.8 * e);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NameDragonPainter old) => false;
}