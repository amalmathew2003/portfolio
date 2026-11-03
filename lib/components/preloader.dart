
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/app_controller.dart';
import '../core/painters.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class _Frame {
  const _Frame(this.label, this.x, this.y, this.w, this.h, this.delay);
  final String label;
  final double x, y, w, h; // fractions of the canvas
  final double delay;
}

const _frames = <_Frame>[
  _Frame('Hero / Frame', 0.05, 0.10, 0.90, 0.85, 0),
  _Frame('Navbar / Component', 0.05, 0.10, 0.90, 0.08, 0.1),
  _Frame('Portrait / Image', 0.42, 0.18, 0.25, 0.65, 0.2),
  _Frame('CTA / Group', 0.05, 0.65, 0.30, 0.20, 0.3),
  _Frame('Stats / Component', 0.78, 0.30, 0.17, 0.40, 0.15),
];

/// Figma-style loading screen with selection frames, crosshairs and a counter.
class Preloader extends StatefulWidget {
  const Preloader({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<Preloader> createState() => _PreloaderState();
}

class _PreloaderState extends State<Preloader> with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _exit;
  int _count = 0;
  bool _done = false;
  bool _holdScheduled = false;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete();
      });
    _ticker = createTicker((elapsed) {
      // wait 500 ms, then count 0 → 100 over 1000 ms
      final ms = elapsed.inMilliseconds - 500;
      final progress = (ms / 1000).clamp(0.0, 1.0);
      final value = (progress * 100).floor();
      if (value != _count) setState(() => _count = value);
      if (value >= 100 && !_holdScheduled) {
        _holdScheduled = true;
        _ticker.stop();
        Future.delayed(const Duration(milliseconds: 500), _finish);
      }
    })..start();
  }

  void _finish() {
    if (_done || !mounted) return;
    setState(() => _done = true);
    app.preloaderDone.value = true;
    _exit.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countStr = '${_count.toString().padLeft(2, '0')}%';
    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final t = const Cubic(0.76, 0, 0.24, 1).transform(_exit.value);
        return Transform.translate(offset: Offset(0, -MediaQuery.sizeOf(context).height * t), child: child);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: ClipRect(
            child: Container(
              color: C.bg,
              child: Stack(
                children: [
                  // ── Figma toolbar ──
                  Positioned(top: 0, left: 0, right: 0, height: 48, child: _toolbar()),
                  // ── Canvas ──
                  Positioned(
                    top: 48,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CustomPaint(
                      painter: DotGridPainter(),
                      child: LayoutBuilder(
                        builder: (context, cons) {
                          final w = cons.maxWidth, h = cons.maxHeight;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final f in _frames)
                                Positioned(
                                  left: f.x * w,
                                  top: f.y * h,
                                  width: f.w * w,
                                  height: f.h * h,
                                  child: _SelectionFrame(frame: f),
                                ),
                              _cross(0.05 * w, 0.10 * h),
                              _cross(0.95 * w, 0.10 * h),
                              _cross(0.05 * w, 0.95 * h),
                              _cross(0.95 * w, 0.95 * h),
                              _cross(0.42 * w, 0.18 * h),
                              // Counter
                              Positioned.fill(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _CountText(key: ValueKey(_count), text: countStr),
                                      const SizedBox(height: 8),
                                      Text('LOADING PORTFOLIO', style: mono(10, color: wh(0.3), ls: 0.2)),
                                    ],
                                  ),
                                ),
                              ),
                              // Skip hint
                              Positioned(
                                bottom: 24,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text('CLICK ANYWHERE TO SKIP', style: mono(10, color: wh(0.2), ls: 0.2)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cross(double x, double y) => Positioned(
    left: x - 8,
    top: y - 8,
    width: 16,
    height: 16,
    child: IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: 7.5, left: 0, right: 0, height: 1, child: ColoredBox(color: op(C.blue, 0.6))),
          Positioned(left: 7.5, top: 0, bottom: 0, width: 1, child: ColoredBox(color: op(C.blue, 0.6))),
        ],
      ),
    ),
  );

  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: wh(0.08))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              children: [
                Positioned(left: 1, top: 1, width: 6, height: 6, child: _sq(C.accent, 1)),
                Positioned(left: 9, top: 1, width: 6, height: 6, child: _sq(C.blue, 3)),
                Positioned(left: 1, top: 9, width: 6, height: 6, child: _sq(const Color(0xFFA855F7), 3)),
                Positioned(left: 9, top: 9, width: 6, height: 6, child: _sq(const Color(0xFF22C55E), 1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: wh(0.12)),
          for (var i = 0; i < 5; i++) ...[
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == 0 ? op(C.blue, 0.2) : Colors.transparent,
                border: Border.all(color: i == 0 ? op(C.blue, 0.4) : Colors.transparent),
              ),
              child: Text(
                const ['M', 'F', 'R', 'T', 'P'][i],
                style: mono(10, color: i == 0 ? C.blue : wh(0.4), h: 1.0),
              ),
            ),
          ],
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('amal-portfolio', style: mono(10, color: wh(0.4))),
        ],
      ),
    );
  }

  Widget _sq(Color c, double r) => DecoratedBox(
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
  );
}

/// `motion.span key={count}` — fades/slides in on every number change.
class _CountText extends StatelessWidget {
  const _CountText({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final size = Bp.clampVw(context, 48, 8, 96);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: 0.5 + 0.5 * t,
        child: Transform.translate(offset: Offset(0, 4 * (1 - t)), child: child),
      ),
      child: Text(text, style: anton(size, ls: -0.02, h: 1.0)),
    );
  }
}

class _SelectionFrame extends StatelessWidget {
  const _SelectionFrame({required this.frame});
  final _Frame frame;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      fromScale: 0.95,
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: (frame.delay * 1000).round()),
      curve: Curves.easeOut,
      child: LayoutBuilder(
        builder: (context, cons) {
          final w = cons.maxWidth - 3, h = cons.maxHeight - 3; // padding box (inside 1.5px border)
          // handle centres (see the original translate(-50%,-50%) maths)
          final centres = <Offset>[
            const Offset(-3, -3),
            Offset(w / 2, -3),
            Offset(w - 3, -3),
            Offset(-3, h / 2),
            Offset(w - 3, h / 2),
            Offset(-3, h - 3),
            Offset(w / 2, h - 3),
            Offset(w - 3, h - 3),
          ];
          return Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(13, 153, 255, 0.05),
              border: Border.all(color: C.blue, width: 1.5),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -24,
                  left: -1,
                  child: Container(
                    color: C.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(frame.label, style: mono(10, ls: 0.05), softWrap: false),
                   ),
                ),
                for (final c in centres)
                  Positioned(
                    left: c.dx - 3,
                    top: c.dy - 3,
                    width: 6,
                    height: 6,
                    child: const ColoredBox(color: C.blue),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
