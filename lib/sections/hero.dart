import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_controller.dart';
import '../core/painters.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> with SingleTickerProviderStateMixin {
  final GlobalKey _heroKey = GlobalKey();

  // framer-motion spring { damping: 25, stiffness: 60 } on the normalised pointer
  late final Ticker _ticker;
  final ValueNotifier<Offset> _par = ValueNotifier(Offset.zero);
  Offset _target = Offset.zero;
  Offset _pos = Offset.zero;
  Offset _vel = Offset.zero;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    app.pointer.addListener(_onPointer);
  }

  void _onPointer() {
    final box = _heroKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final tl = box.localToGlobal(Offset.zero);
    final p = app.pointer.value;
    _target = Offset((p.dx - tl.dx) / box.size.width - 0.5, (p.dy - tl.dy) / box.size.height - 0.5);
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration e) {
    final dt = _last == Duration.zero ? 1 / 60 : (e - _last).inMicroseconds / 1e6;
    _last = e;
    final h = math.min(dt, 1 / 30);
    const k = 60.0, c = 25.0;
    const n = 4;
    final s = h / n;
    var px = _pos.dx, py = _pos.dy, vx = _vel.dx, vy = _vel.dy;
    for (var i = 0; i < n; i++) {
      vx += (-k * (px - _target.dx) - c * vx) * s;
      vy += (-k * (py - _target.dy) - c * vy) * s;
      px += vx * s;
      py += vy * s;
    }
    _pos = Offset(px, py);
    _vel = Offset(vx, vy);
    if ((_pos - _target).distance < 1e-4 && _vel.distance < 1e-4) {
      _pos = _target;
      _vel = Offset.zero;
      _ticker.stop();
    }
    _par.value = _pos;
  }

  @override
  void dispose() {
    app.pointer.removeListener(_onPointer);
    _ticker.dispose();
    _par.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = Bp.pad(context);

    return KeyedSubtree(
      key: _heroKey,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(color: C.bg),
        child: Stack(
          children: [
            // hero-grid background
            Positioned.fill(child: CustomPaint(painter: HeroGridPainter())),
            // ── RED SCANNING LINE ──
            const Positioned.fill(child: _ScanLine()),
            // ── FLOATING PARTICLES ──
            const Positioned.fill(child: _Particles()),
            // ── GIANT BACKGROUND WORD ──
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: Center(
                    child: ValueListenableBuilder<Offset>(
                      valueListenable: _par,
                      builder: (context, p, child) =>
                          Transform.translate(offset: Offset(p.dx * -35, p.dy * -20), child: child),
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: double.infinity,
                        child: Text(
                          'PORTFOLIO',
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: anton(size.width * 0.22, color: op(C.accent, 0.14), ls: -0.025, h: 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── FOREGROUND CONTENT ──
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 112, pad, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 1280,
                      minHeight: math.max(0.0, size.height - 112 - 48),
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: app.preloaderDone,
                      builder: (context, ready, _) =>
                          _Foreground(contentWidth: Bp.content(context), trigger: ready),
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

// ─────────────────────────────────────────────────────────────────────────────
class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, cons) => LoopAnim(
          duration: const Duration(seconds: 4),
          builder: (context, t) => Stack(
            children: [
              Positioned(
                top: -2 + t * (cons.maxHeight + 2),
                left: 0,
                right: 0,
                height: 1,
                child: Opacity(
                  opacity: 0.3,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, C.accent, Colors.transparent]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particles extends StatelessWidget {
  const _Particles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, cons) {
          return Stack(
            children: [
              for (var i = 0; i < 14; i++)
                Positioned(
                  left: cons.maxWidth * ((i * 7.5 + 4) % 95) / 100,
                  top: cons.maxHeight * ((i * 13.3 + 8) % 90) / 100,
                  child: _Particle(
                    size: ((i % 3) + 2).toDouble(),
                    duration: Duration(milliseconds: ((3 + (i % 4) * 1.5) * 1000).round()),
                    delay: Duration(milliseconds: ((i % 5) * 0.4 * 1000).round()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  const _Particle({required this.size, required this.duration, required this.delay});
  final double size;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return LoopAnim(
      duration: duration,
      delay: delay,
      builder: (context, t) {
        // keyframes [a, b, a] with easeInOut per segment
        final v = Curves.easeInOut.transform(1 - (2 * t - 1).abs());
        return Transform.translate(
          offset: Offset(0, -12 + 24 * v),
          child: Opacity(
            opacity: 0.15 + 0.30 * v,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Foreground extends StatelessWidget {
  const _Foreground({required this.contentWidth, required this.trigger});
  final double contentWidth;
  final bool trigger;

  @override
  Widget build(BuildContext context) {
    final lg = Bp.lg(context);
    final md = Bp.md(context);

    final left = _LeftColumn(lg: lg, md: md, trigger: trigger);
    final right = _StatsColumn(lg: lg, md: md, trigger: trigger);

    final Widget grid = lg
        ? Grid(
            columns: 12,
            gap: 32,
            width: contentWidth,
            align: CrossAxisAlignment.center,
            items: [GridItem(8, left), GridItem(4, right)],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(height: 32),
              Padding(padding: const EdgeInsets.only(top: 32), child: right),
            ],
          );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: grid,
        ),
        Container(
          padding: const EdgeInsets.only(top: 32),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: wh(0.06))),
          ),
          child: const _BottomRow(),
        ),
      ],
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.lg, required this.md, required this.trigger});
  final bool lg;
  final bool md;
  final bool trigger;

  @override
  Widget build(BuildContext context) {
    final h1 = Bp.clampVw(context, 44, 6.5, 88);
    final nameSize = lg ? 72.0 : (md ? 60.0 : 36.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Script intro
        Reveal(
          dy: 20,
          trigger: trigger,
          duration: const Duration(milliseconds: 600),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text("Hello, I'm", style: caveat(md ? 30 : 24, color: C.muted)),
          ),
        ),
        // Name
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SlideUpClip(
            trigger: trigger,
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 100),
            child: Text('AMAL MATHEW', style: anton(nameSize, ls: -0.025, h: 1.0)),
          ),
        ),
        // Role pill
        Reveal(
          dx: -20,
          trigger: trigger,
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 250),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RedDot(),
                const SizedBox(width: 8),
                Text('FLUTTER DEVELOPER', style: mono(12, color: C.accent, ls: 0.25, bold: true)),
                const SizedBox(width: 8),
                Text('/', style: mono(12, color: wh(0.2))),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('KERALA, INDIA', style: mono(11, color: C.muted, ls: 0.05)),
                ),
              ],
            ),
          ),
        ),
        // Headline
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SlideUpClip(
            trigger: trigger,
            duration: const Duration(milliseconds: 850),
            delay: const Duration(milliseconds: 300),
            child: Text('I BUILD MOBILE', style: anton(h1, ls: -0.025, h: 0.88)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SlideUpClip(
            trigger: trigger,
            duration: const Duration(milliseconds: 850),
            delay: const Duration(milliseconds: 400),
            child: Text('EXPERIENCES THAT MATTER.', style: anton(h1, color: C.accent, ls: -0.025, h: 0.88)),
          ),
        ),
        // Bio
        Reveal(
          dy: 20,
          trigger: trigger,
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 550),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 576),
              child: Text(
                'Flutter developer with ~1.3 years of professional experience crafting cross-platform mobile applications. Specialized in clean architecture, state management, and seamless REST & Firebase integrations.',
                style: inter(md ? 16 : 14, color: C.muted, h: 1.625),
              ),
            ),
          ),
        ),
        // Buttons
        Reveal(
          dy: 20,
          trigger: trigger,
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 700),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Hov(
                cursor: CursorMode.hover,
                onTap: () => app.scrollToId('work'),
                builder: (context, h) => AnimatedContainer(
                  duration: kMs300,
                  curve: kTw,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: h ? C.accentHover : C.accent,
                    boxShadow: const [
                      BoxShadow(color: Color.fromRGBO(230, 57, 70, 0.3), blurRadius: 24, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('VIEW PROJECTS', style: anton(16, ls: 0.05)),
                      const SizedBox(width: 12),
                      ATranslate(
                        offset: Offset(h ? 4 : 0, 0),
                        child: const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Hov(
                cursor: CursorMode.hover,
                onTap: () => app.scrollToId('contact'),
                builder: (context, h) => AnimatedContainer(
                  duration: kMs300,
                  curve: kTw,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: h ? Colors.white : Colors.transparent,
                    border: Border.all(color: h ? Colors.white : wh(0.2)),
                  ),
                  child: ATxt(
                    'CONTACT ME',
                    anton(16, color: h ? Colors.black : Colors.white, ls: 0.05),
                    duration: kMs300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsColumn extends StatelessWidget {
  const _StatsColumn({required this.lg, required this.md, required this.trigger});
  final bool lg;
  final bool md;
  final bool trigger;

  Widget _stat(String value, String label, Color color, double size, int delayMs) {
    return Reveal(
      dx: 30,
      trigger: trigger,
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delayMs),
      child: Hov(
        builder: (context, h) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: lg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            AScale(
              scale: h ? 1.05 : 1,
              alignment: Alignment.centerRight,
              child: Text(value, style: anton(size, color: color, ls: -0.025, h: 1.0)),
            ),
            const SizedBox(height: 4),
            Text(label, style: mono(10, color: C.muted, ls: 0.2)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Align(
    alignment: lg ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(width: 64, height: 1, color: wh(0.08)),
  );

  @override
  Widget build(BuildContext context) {
    final big = md ? 48.0 : 36.0;
    final small = md ? 36.0 : 30.0;

    final box = ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: op(C.bg, 0.6),
            border: Border(
              left: lg ? BorderSide.none : BorderSide(color: wh(0.08)),
              right: lg ? BorderSide(color: wh(0.08)) : BorderSide.none,
            ),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stat('1.3 YRS', 'PROFESSIONAL EXP', C.accent, big, 400),
                const SizedBox(height: 24),
                _divider(),
                const SizedBox(height: 24),
                _stat('3 APPS', 'FEATURED PRODUCTION BUILDS', Colors.white, big, 550),
                const SizedBox(height: 24),
                _divider(),
                const SizedBox(height: 24),
                _stat('FLUTTER', 'CORE ARCHITECTURE', C.accent, small, 700),
              ],
            ),
          ),
        ),
      ),
    );

    return Align(alignment: lg ? Alignment.centerRight : Alignment.centerLeft, child: box);
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Hov(
          cursor: CursorMode.hover,
          onTap: () => app.scrollToId('skills'),
          builder: (context, h) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: kMs150,
                curve: kTw,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: h ? C.accent : wh(0.15)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: AScale(
                        scale: h ? 1.1 : 1,
                        child: CustomPaint(size: const Size(14, 14), painter: PlayFilledPainter(C.accent)),
                      ),
                    ),
                    const Positioned(top: -4, right: -4, child: Ping(size: 8, color: C.accent)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ATxt('TECH STACK', mono(10, color: h ? Colors.white : C.muted, ls: 0.2)),
                  Text('EXPLORE TOOLS ↓', style: mono(9, color: const Color(0xFF555555), ls: 0.1)),
                ],
              ),
            ],
          ),
        ),
        Hov(
          sysCursor: SystemMouseCursors.click,
          onTap: () => app.scrollToId('work'),
          builder: (context, h) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ATxt('SCROLL THROUGH', mono(10, color: h ? C.accent : C.muted, ls: 0.25)),
              const SizedBox(height: 6),
              LoopAnim(
                duration: const Duration(milliseconds: 1500),
                builder: (context, t) {
                  final v = Curves.easeInOut.transform(1 - (2 * t - 1).abs());
                  return Transform.translate(
                    offset: Offset(0, 6 * v),
                    child: const Icon(LucideIcons.arrowDown, size: 14, color: C.accent),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
