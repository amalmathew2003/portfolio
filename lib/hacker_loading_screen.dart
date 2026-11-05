import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Terminal style loading screen: a hooded hacker made of 0, 1 and hacking
/// words, lit by the glow of his laptop. Black background, white text only.
///
/// Usage:
/// HackerLoadingScreen(
///   duration: Duration(seconds: 6),
///   onFinished: () {
///     Navigator.of(context).pushReplacement(
///       MaterialPageRoute(builder: (_) => const MyPortfolio()),
///     );
///   },
/// )
class HackerLoadingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration duration;
  final String title;
  final Color color;
  final bool showRain;

  /// Number of character rows used to draw the hacker.
  /// 38 looks good and is light. Use 30 for weak devices, 46 for more detail.
  final int detail;

  /// Overall size of the screen content. 1.0 = big, 0.7 = small like a
  /// terminal (default), 0.55 = very small.
  final double scale;

  const HackerLoadingScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(seconds: 6),
    this.title = 'PORTFOLIO',
    this.color = const Color(0xFFFFFFFF),
    this.showRain = true,
    this.detail = 38,
    this.scale = 0.7,
  });

  @override
  State<HackerLoadingScreen> createState() => _HackerLoadingScreenState();
}

// ----------------------------------------------------------------- log lines
const List<List<Object>> _kLogs = [
  [0.00, '> boot sequence initiated'],
  [0.06, '> mounting /dev/portfolio ...... [ OK ]'],
  [0.16, '> bypassing firewall ........... [ OK ]'],
  [0.28, '> injecting payload ............ [ OK ]'],
  [0.42, '> decrypting projects.db ....... [ OK ]'],
  [0.55, '> loading skills.json .......... [ OK ]'],
  [0.68, '> compiling pixels .............. [ OK ]'],
  [0.82, '> opening secure channel ........ [ OK ]'],
  [0.94, '> root access granted'],
  [1.00, '> welcome, visitor'],
];

class _HackerLoadingScreenState extends State<HackerLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _HackerModel _model;
  final ValueNotifier<int> _tick = ValueNotifier(0);
  final _GlyphCache _hackerCache = _GlyphCache();
  final _GlyphCache _rainCache = _GlyphCache();
  final List<int> _logStart = List.filled(_kLogs.length, -1);

  double _progress = 0;
  Duration _lastStep = Duration.zero;
  Duration? _doneAt;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _model = _HackerModel(math.Random(), widget.detail);
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

  void _onTick(Duration elapsed) {
    // about 14 updates per second: enough for a terminal look, very light
    if (elapsed - _lastStep < const Duration(milliseconds: 70)) return;
    _lastStep = elapsed;

    _progress = _fake(elapsed.inMilliseconds / widget.duration.inMilliseconds);
    _model.step(_progress);
    _tick.value++;

    for (int i = 0; i < _kLogs.length; i++) {
      if (_logStart[i] < 0 && _progress >= (_kLogs[i][0] as double)) {
        _logStart[i] = _tick.value;
      }
    }

    if (_progress >= 1 && !_finished) {
      _doneAt ??= elapsed;
      if (elapsed - _doneAt! > const Duration(milliseconds: 1100)) {
        _finished = true;
        _ticker.stop();
        widget.onFinished();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    // Material gives every Text a proper default style. Without it Flutter
    // draws the ugly yellow double underline under all words.
    return Material(
      color: const Color(0xFF000000),
      child: Stack(
        children: [
          if (widget.showRain)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _RainPainter(_model, color, _rainCache, _tick),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 820;

                final left = Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: _TitleBar(
                        tick: _tick,
                        title: widget.title,
                        color: color,
                        scale: widget.scale,
                        progressOf: () => _progress,
                      ),
                    ),
                    Expanded(
                      child: RepaintBoundary(
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: _HackerPainter(
                              _model,
                              color,
                              _hackerCache,
                              _tick,
                              scale: widget.scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                final terminal = Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TerminalPanel(
                    tick: _tick,
                    color: color,
                    progressOf: () => _progress,
                    startsOf: () => _logStart,
                    scale: widget.scale,
                  ),
                );

                if (wide) {
                  return Row(
                    children: [
                      Expanded(flex: 6, child: left),
                      Expanded(flex: 4, child: Center(child: terminal)),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(flex: 6, child: left),
                    terminal,
                  ],
                );
              },
            ),
          ),
          // CRT scanlines + vignette (static, painted once)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _CrtPainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================= title (decrypt text)
class _TitleBar extends StatelessWidget {
  final ValueNotifier<int> tick;
  final String title;
  final Color color;
  final double scale;
  final double Function() progressOf;

  const _TitleBar({
    required this.tick,
    required this.title,
    required this.color,
    required this.scale,
    required this.progressOf,
  });

  String _scramble(String s, double p, int t) {
    const pool = '01#\$%&@*<>/';
    final reveal = (p * 1.25 * s.length).floor();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (s[i] == ' ' || i < reveal) {
        b.write(s[i]);
      } else {
        b.write(pool[math.Random(t * 31 + i).nextInt(pool.length)]);
      }
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tick,
      builder: (context, t, _) {
        final p = progressOf();
        final done = p >= 1;
        final text =
            done ? 'ACCESS GRANTED' : 'ACCESSING ${_scramble(title, p, t)}';
        final glitch = !done && (t % 41) < 2;
        final style = TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier New', 'Consolas', 'Menlo'],
          fontSize: 20 * (0.6 + 0.4 * scale),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          decoration: TextDecoration.none,
          color: color,
        );
        final blink = (t % 12) < 6 ? '_' : ' ';

        return Stack(
          alignment: Alignment.center,
          children: [
            if (glitch)
              Transform.translate(
                offset: const Offset(-3, 0),
                child: Text(
                  text,
                  style: style.copyWith(color: const Color(0x99FFFFFF)),
                ),
              ),
            if (glitch)
              Transform.translate(
                offset: const Offset(3, 0),
                child: Text(
                  text,
                  style: style.copyWith(color: const Color(0x55FFFFFF)),
                ),
              ),
            Text('$text${done ? '' : blink}', style: style),
          ],
        );
      },
    );
  }
}

// ======================================================== terminal side panel
class _TerminalPanel extends StatelessWidget {
  final ValueNotifier<int> tick;
  final Color color;
  final double Function() progressOf;
  final List<int> Function() startsOf;
  final double scale;

  const _TerminalPanel({
    required this.tick,
    required this.color,
    required this.progressOf,
    required this.startsOf,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final k = 0.6 + 0.4 * scale; // text size factor
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400 * k),
      child: Container(
        padding: EdgeInsets.all(10 * k),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(150),
          border: Border.all(color: color.withAlpha(120)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (context, t, _) {
            final p = progressOf();
            final starts = startsOf();
            final pct = (p * 100).floor();
            const barLen = 20;
            final filled = (p * barLen).floor();
            final bar = '█' * filled + '░' * (barLen - filled);
            final kb = (p * 4096).floor();

            // lines that already started typing
            final shown = <int>[];
            for (int i = 0; i < _kLogs.length; i++) {
              if (starts[i] >= 0) shown.add(i);
            }
            final last7 =
                shown.length > 7 ? shown.sublist(shown.length - 7) : shown;
            final cursor = (t % 10) < 5 ? '█' : ' ';

            final base = TextStyle(
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Courier New', 'Consolas', 'Menlo'],
              fontSize: 12.5 * k,
              height: 1.35,
              decoration: TextDecoration.none,
              color: color.withAlpha(200),
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final c in const [
                      Color(0xFFFFFFFF),
                      Color(0x99FFFFFF),
                      Color(0x44FFFFFF),
                    ])
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(right: 6),
                        decoration:
                            BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                    const SizedBox(width: 6),
                    Text('root@portfolio:~#',
                        style: base.copyWith(fontSize: 10 * k)),
                  ],
                ),
                const SizedBox(height: 10),
                for (int n = 0; n < last7.length; n++)
                  _logLine(
                    _kLogs[last7[n]][1] as String,
                    ((t - starts[last7[n]]) * 3).clamp(0, 999).toInt(),
                    base,
                    isLast: n == last7.length - 1,
                    cursor: cursor,
                  ),
                const SizedBox(height: 12),
                Text(
                  '[$bar] $pct%',
                  style: base.copyWith(
                    color: color,
                    fontSize: 14 * k,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text('payload  $kb / 4096 KB',
                    style: base.copyWith(fontSize: 10 * k)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _logLine(String full, int typed, TextStyle base,
      {required bool isLast, required String cursor}) {
    final text = full.substring(0, math.min(typed, full.length));
    const ok = '[ OK ]';
    final i = text.indexOf(ok);
    final spans = <InlineSpan>[];
    if (i >= 0) {
      spans.add(TextSpan(text: text.substring(0, i)));
      spans.add(const TextSpan(
        text: ok,
        style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
      ));
    } else {
      spans.add(TextSpan(text: text));
    }
    if (isLast) spans.add(TextSpan(text: ' $cursor'));

    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
    );
  }
}

// ================================================================ the model
enum _Z { none, hood, body, arm, face, eye, laptop, logo, hand, base, string }

class _Planted {
  final List<int> keys;
  int ttl;
  _Planted(this.keys, this.ttl);
}

class _Drop {
  double nx;
  double ny;
  double speed;
  int len;
  _Drop(this.nx, this.ny, this.speed, this.len);
}

class _HackerModel {
  static const double cw = 0.6; // glyph width compared to glyph height
  static const double w0 = 50; // drawing space
  static const double h0 = 50;
  static const double cx0 = 25;

  static const List<String> words = [
    'ROOT', 'SUDO', 'HACK', '0DAY', 'SSH', 'EXPLOIT', 'NULL', 'PWN',
    'ADMIN', 'ENCRYPT', 'SHELL', 'BYPASS', 'KERNEL', 'ZERO',
  ];

  // ---- shapes of the hacker (drawing space 50 x 50) ----
  static List<Offset> _mir(List<Offset> half) => [
        ...half,
        ...half.reversed.map((p) => Offset(2 * cx0 - p.dx, p.dy)),
      ];

  static final List<Offset> _hood = _mir(const [
    Offset(25, 0.8), Offset(28.5, 1.6), Offset(31.5, 4), Offset(33.2, 8),
    Offset(33.8, 13), Offset(33.2, 18), Offset(31.5, 22.5), Offset(29.5, 24.5),
  ]);
  static final List<Offset> _torso = _mir(const [
    Offset(29.5, 22), Offset(36, 24.5), Offset(42, 29), Offset(45.5, 35),
    Offset(47, 43), Offset(47.5, 50),
  ]);
  static const List<Offset> _laptop = [
    Offset(13.5, 33), Offset(36.5, 33), Offset(38, 45), Offset(12, 45),
  ];
  static const List<Offset> _base = [
    Offset(10, 45), Offset(40, 45), Offset(43.5, 48.5), Offset(6.5, 48.5),
  ];
  static const List<Offset> _sleeveL = [
    Offset(10, 28), Offset(15, 27), Offset(17, 40), Offset(17, 46),
    Offset(10, 46), Offset(6, 40),
  ];
  static final List<Offset> _sleeveR =
      _sleeveL.map((p) => Offset(2 * cx0 - p.dx, p.dy)).toList();

  final math.Random rng;
  final int rows;
  final int cols;
  late final List<List<_Z>> zones;
  late final List<List<String>> chars;
  late final List<List<double>> bright;
  late final List<List<double>> tint; // cyan light from the laptop, 0..1
  final Map<int, String> _override = {};
  final List<_Planted> _planted = [];
  final List<_Drop> drops = [];

  double revealRows = 0;
  bool eyesClosed = false;
  int _blinkLeft = 0;
  int stepCount = 0;

  // glitch (a few rows jump sideways for a moment)
  int glitchTtl = 0;
  int glitchRow = 0;
  int glitchRows = 0;
  double glitchDx = 0;

  _HackerModel(this.rng, this.rows)
      : cols = (rows * w0 / h0 / cw).round() {
    zones = List.generate(
      rows,
      (r) => List.generate(cols, (c) => _zoneAt(c, r)),
    );
    chars = List.generate(
      rows,
      (r) => List.generate(cols, (c) => rng.nextBool() ? '1' : '0'),
    );
    bright = List.generate(
      rows,
      (r) => List.generate(cols, (c) => _brightAt(c, r)),
    );
    tint = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        final x = (c + 0.5) / cols * w0;
        final y = (r + 0.5) / rows * h0;
        final dx = x - cx0;
        final dy = y - 36;
        final d = math.sqrt(dx * dx + dy * dy);
        final t = math.max(0.0, 1 - d / 24);
        return (math.pow(t, 1.4).toDouble() * 4).round() / 4; // 5 levels
      });
    });
    for (int i = 0; i < 18; i++) {
      drops.add(_newDrop(randomY: true));
    }
  }

  _Drop _newDrop({bool randomY = false}) => _Drop(
        rng.nextDouble(),
        randomY ? rng.nextDouble() * 1.2 : -0.1 - rng.nextDouble() * 0.3,
        0.008 + rng.nextDouble() * 0.014,
        6 + rng.nextInt(7),
      );

  static bool _pip(double x, double y, List<Offset> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].dx, yi = poly[i].dy;
      final xj = poly[j].dx, yj = poly[j].dy;
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  _Z _zoneAt(int c, int r) {
    final x = (c + 0.5) / cols * w0;
    final y = (r + 0.5) / rows * h0;

    bool ell(double ex, double ey, double rx, double ry) {
      final a = (x - ex) / rx;
      final b = (y - ey) / ry;
      return a * a + b * b <= 1;
    }

    if (ell(cx0 - 3.0, 12.2, 1.9, 0.8) || ell(cx0 + 3.0, 12.2, 1.9, 0.8)) {
      return _Z.eye;
    }
    if (ell(cx0, 13.2, 6.4, 8.2) && y < 22) return _Z.face;
    if (ell(cx0, 39, 2.6, 2.6)) return _Z.logo;
    if (ell(13.5, 46.5, 3.6, 1.9) || ell(36.5, 46.5, 3.6, 1.9)) {
      return _Z.hand;
    }
    if (((x - (cx0 - 2.3)).abs() < 0.5 || (x - (cx0 + 2.3)).abs() < 0.5) &&
        y >= 24 &&
        y <= 32) {
      return _Z.string;
    }
    if (_pip(x, y, _laptop)) return _Z.laptop;
    if (_pip(x, y, _base)) return _Z.base;
    if (_pip(x, y, _sleeveL) || _pip(x, y, _sleeveR)) return _Z.arm;
    if (_pip(x, y, _torso)) return _Z.body;
    if (_pip(x, y, _hood)) return _Z.hood;
    return _Z.none;
  }

  double _brightAt(int c, int r) {
    final z = zones[r][c];
    if (z == _Z.none || z == _Z.face) return 0;

    // cells next to a different zone get an outline
    bool edge = false;
    const d = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    for (final o in d) {
      final nr = r + o[0];
      final nc = c + o[1];
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
        edge = true;
      } else if (zones[nr][nc] != z) {
        edge = true;
      }
    }

    double b;
    switch (z) {
      case _Z.hood:
        b = 0.62;
        break;
      case _Z.body:
        b = 0.36;
        break;
      case _Z.arm:
        b = 0.50;
        break;
      case _Z.laptop:
        b = 0.72;
        break;
      case _Z.base:
        b = 0.55;
        break;
      default:
        b = 0.95;
    }
    if (edge) b = math.min(1.0, b + 0.32);
    return b;
  }

  String charAt(int r, int c) => _override[r * cols + c] ?? chars[r][c];
  bool isWordCell(int r, int c) => _override.containsKey(r * cols + c);

  void step(double progress) {
    stepCount++;
    revealRows = (progress / 0.85).clamp(0.0, 1.0).toDouble() * rows;

    // flicker some digits
    final flips = (rows * cols * 0.025).round();
    for (int i = 0; i < flips; i++) {
      final r = rng.nextInt(rows);
      final c = rng.nextInt(cols);
      if (zones[r][c] != _Z.none) chars[r][c] = rng.nextBool() ? '1' : '0';
    }

    // blink
    if (_blinkLeft > 0) {
      _blinkLeft--;
      eyesClosed = true;
    } else {
      eyesClosed = false;
      if (rng.nextInt(55) == 0) _blinkLeft = 2;
    }

    // glitch
    if (glitchTtl > 0) {
      glitchTtl--;
    } else if (revealRows > rows * 0.5 && rng.nextInt(40) == 0) {
      glitchTtl = 2 + rng.nextInt(3);
      glitchRow = rng.nextInt(rows - 6);
      glitchRows = 2 + rng.nextInt(4);
      glitchDx = (rng.nextBool() ? 1 : -1) * (1.0 + rng.nextInt(3));
    }

    // hacking words appear inside the figure for a moment
    for (final p in _planted) {
      p.ttl--;
    }
    _planted.removeWhere((p) {
      if (p.ttl <= 0) {
        for (final k in p.keys) {
          _override.remove(k);
        }
        return true;
      }
      return false;
    });
    if (revealRows > rows * 0.4 && _planted.length < 5 && rng.nextDouble() < 0.4) {
      _plant();
    }

    // rain
    for (int i = 0; i < drops.length; i++) {
      final d = drops[i];
      d.ny += d.speed;
      if (d.ny - d.len * 0.03 > 1.05) drops[i] = _newDrop();
    }
  }

  void _plant() {
    final word = words[rng.nextInt(words.length)];
    final maxRow = math.min(rows - 1, revealRows.floor());
    for (int attempt = 0; attempt < 14; attempt++) {
      final r = rng.nextInt(maxRow + 1);
      final c = rng.nextInt(cols);
      if (c + word.length > cols) continue;
      bool ok = true;
      for (int i = 0; i < word.length; i++) {
        final z = zones[r][c + i];
        if ((z != _Z.body && z != _Z.hood && z != _Z.laptop && z != _Z.arm) ||
            _override.containsKey(r * cols + c + i)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      final keys = <int>[];
      for (int i = 0; i < word.length; i++) {
        final k = r * cols + c + i;
        _override[k] = word[i];
        keys.add(k);
      }
      _planted.add(_Planted(keys, 8 + rng.nextInt(10)));
      return;
    }
  }
}

// ========================================================= glyph cache + paint
class _GlyphCache {
  final Map<int, TextPainter> _m = {};
  double _fs = 0;

  TextPainter get(String ch, Color color, double fs, {bool bold = false}) {
    if (fs != _fs) {
      _m.clear();
      _fs = fs;
    }
    final key = Object.hash(ch, color, bold);
    return _m.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(
            color: color,
            fontSize: fs,
            height: 1.0,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier New', 'Consolas', 'Menlo'],
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }
}

Color _quantize(Color base, double a) {
  final q = (a.clamp(0.0, 1.0).toDouble() * 8).round() / 8;
  return base.withAlpha((q * 255).round());
}

class _HackerPainter extends CustomPainter {
  final _HackerModel m;
  final Color color;
  final _GlyphCache cache;
  final double scale;

  // light color of the laptop (white, so the whole screen stays black and white)
  static const Color _cyan = Color(0xFFFFFFFF);

  _HackerPainter(this.m, this.color, this.cache, Listenable repaint,
      {this.scale = 1})
      : super(repaint: repaint);

  Color _zoneColor(_Z z, double a, double tint, bool front, bool word) {
    if (front) return Colors.white.withAlpha(235);
    Color base;
    switch (z) {
      case _Z.eye:
        base = const Color(0xFFFFFFFF);
        a = 1;
        break;
      case _Z.logo:
        base = Colors.white;
        a = 1;
        break;
      case _Z.laptop:
        base = _cyan;
        break;
      case _Z.hand:
        base = Color.lerp(color, Colors.white, 0.3)!;
        break;
      case _Z.string:
        base = Color.lerp(color, Colors.white, 0.5)!;
        break;
      default:
        base = Color.lerp(color, _cyan, tint * 0.85)!;
        a = math.min(1.0, a + tint * 0.25);
    }
    if (word) {
      base = Color.lerp(base, Colors.white, 0.65)!;
      a = 1;
    }
    return _quantize(base, a);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cols = m.cols;
    final rows = m.rows;

    final fs = math.min(
      size.width / (cols * _HackerModel.cw),
      size.height / rows,
    ) * scale;
    if (fs <= 2) return;

    final cellW = fs * _HackerModel.cw;
    final cellH = fs;
    final ox = (size.width - cols * cellW) / 2;
    final oy = (size.height - rows * cellH) / 2;

    final reveal = m.revealRows;
    final scanning = reveal < rows - 0.01;
    final maxRow = math.min(rows - 1, reveal.floor());

    for (int r = 0; r <= maxRow; r++) {
      final front = scanning && r >= reveal - 1.2;
      final glitched = m.glitchTtl > 0 &&
          r >= m.glitchRow &&
          r < m.glitchRow + m.glitchRows;
      final shift = glitched ? m.glitchDx * cellW : 0.0;

      for (int c = 0; c < cols; c++) {
        final z = m.zones[r][c];
        if (z == _Z.none || z == _Z.face) continue;

        String ch = m.charAt(r, c);
        if (z == _Z.eye && m.eyesClosed) ch = '-';

        final word = m.isWordCell(r, c);
        final col = _zoneColor(z, m.bright[r][c], m.tint[r][c], front, word);
        final tp = cache.get(ch, col, fs * 0.92, bold: word || z == _Z.eye);

        tp.paint(
          canvas,
          Offset(ox + shift + c * cellW + (cellW - tp.width) / 2, oy + r * cellH),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HackerPainter old) => false;
}

class _RainPainter extends CustomPainter {
  final _HackerModel m;
  final Color color;
  final _GlyphCache cache;

  _RainPainter(this.m, this.color, this.cache, Listenable repaint)
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    const fs = 14.0;
    for (int i = 0; i < m.drops.length; i++) {
      final d = m.drops[i];
      final x = (d.nx * (size.width - fs)).floorToDouble();
      for (int k = 0; k < d.len; k++) {
        final y = (d.ny - k * 0.03) * size.height;
        if (y < 0 || y > size.height) continue;
        final a = k == 0 ? 0.55 : (1 - k / d.len) * 0.28;
        final ch = ((i + k + m.stepCount) % 2 == 0) ? '0' : '1';
        final base = k == 0 ? Color.lerp(color, Colors.white, 0.5)! : color;
        cache.get(ch, _quantize(base, a), fs).paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => false;
}

class _CrtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = Colors.black.withAlpha(46);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withAlpha(170)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CrtPainter old) => false;
}