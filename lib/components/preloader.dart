import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/painters.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class _Frame {
  const _Frame(this.label, this.x, this.y, this.w, this.h, this.delay);
  final String label;
  final double x, y, w, h; // fractions of canvas
  final double delay;
}

const _frames = <_Frame>[
  _Frame('Hero / Frame', 0.05, 0.10, 0.90, 0.85, 0),
  _Frame('Navbar / Component', 0.05, 0.10, 0.90, 0.08, 0.08),
  _Frame('Display / Typography', 0.08, 0.24, 0.46, 0.36, 0.16),
  _Frame('CTA / Group', 0.08, 0.66, 0.30, 0.18, 0.24),
  _Frame('Stats / Component', 0.76, 0.28, 0.19, 0.42, 0.12),
];

/// Blueprint canvas loading screen with smooth blueprint frames, crosshairs & counter.
class Preloader extends StatefulWidget {
  const Preloader({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<Preloader> createState() => _PreloaderState();
}

class _PreloaderState extends State<Preloader> with TickerProviderStateMixin {
  late final AnimationController _countCtrl;
  late final AnimationController _exitCtrl;
  late final Animation<double> _countAnim;

  int _count = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _countAnim = CurvedAnimation(
      parent: _countCtrl,
      curve: const Cubic(0.25, 0.1, 0.25, 1.0),
    )..addListener(() {
        final val = (_countAnim.value * 100).floor().clamp(0, 100);
        if (val != _count) {
          setState(() => _count = val);
        }
      })..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          Future.delayed(const Duration(milliseconds: 400), _finish);
        }
      });

    // Short initial delay before count starts
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _countCtrl.forward();
    });
  }

  void _finish() {
    if (_done || !mounted) return;
    setState(() => _done = true);
    app.preloaderDone.value = true;
    _exitCtrl.forward();
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final countStr = '${_count.toString().padLeft(2, '0')}%';

    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, child) {
        final t = const Cubic(0.76, 0, 0.24, 1).transform(_exitCtrl.value);
        return Transform.translate(
          offset: Offset(0, -size.height * t),
          child: child,
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: ClipRect(
            child: Container(
              color: const Color(0xFF090909),
              child: Stack(
                children: [
                  // ── Clean Top Header (Figma icons removed) ──
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: _topHeader(),
                  ),

                  // ── Blueprint Canvas Area ──
                  Positioned(
                    top: 48,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CustomPaint(
                      painter: DotGridPainter(),
                      child: LayoutBuilder(
                        builder: (context, cons) {
                          final w = cons.maxWidth;
                          final h = cons.maxHeight;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Selection Frames
                              for (final f in _frames)
                                Positioned(
                                  left: f.x * w,
                                  top: f.y * h,
                                  width: f.w * w,
                                  height: f.h * h,
                                  child: _SelectionFrame(frame: f),
                                ),

                              // Corner crosshairs
                              _cross(0.05 * w, 0.10 * h),
                              _cross(0.95 * w, 0.10 * h),
                              _cross(0.05 * w, 0.95 * h),
                              _cross(0.95 * w, 0.95 * h),

                              // Central Counter
                              Positioned.fill(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        countStr,
                                        style: anton(
                                          Bp.clampVw(context, 54, 8, 96),
                                          ls: -0.02,
                                          h: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'LOADING PORTFOLIO',
                                        style: mono(11, color: wh(0.4), ls: 0.25),
                                      ),
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
                                  child: Text(
                                    'CLICK ANYWHERE TO SKIP',
                                    style: mono(10, color: wh(0.25), ls: 0.2),
                                  ),
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
          Positioned(
            top: 7.5,
            left: 0,
            right: 0,
            height: 1,
            child: ColoredBox(color: op(C.blue, 0.6)),
          ),
          Positioned(
            left: 7.5,
            top: 0,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: op(C.blue, 0.6)),
          ),
        ],
      ),
    ),
  );

  Widget _topHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border(bottom: BorderSide(color: wh(0.08))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: C.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'AMAL MATHEW',
            style: mono(11, color: Colors.white, ls: 0.15, bold: true),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 16, color: wh(0.12)),
          const SizedBox(width: 16),
          Text(
            'FLUTTER ARCHITECTURE',
            style: mono(10, color: wh(0.4), ls: 0.1),
          ),
          const Spacer(),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('amal-mathew-portfolio', style: mono(10, color: wh(0.4))),
        ],
      ),
    );
  }
}

class _SelectionFrame extends StatelessWidget {
  const _SelectionFrame({required this.frame});
  final _Frame frame;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      fromScale: 0.96,
      duration: const Duration(milliseconds: 450),
      delay: Duration(milliseconds: (frame.delay * 1000).round()),
      curve: Curves.easeOutCubic,
      child: LayoutBuilder(
        builder: (context, cons) {
          final w = cons.maxWidth - 3;
          final h = cons.maxHeight - 3;

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
              color: const Color.fromRGBO(13, 153, 255, 0.04),
              border: Border.all(color: C.blue, width: 1.5),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -22,
                  left: -1,
                  child: Container(
                    color: C.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      frame.label,
                      style: mono(9, ls: 0.05),
                      softWrap: false,
                    ),
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
