import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_controller.dart';
import '../core/painters.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class StatementSection extends StatefulWidget {
  const StatementSection({super.key});

  @override
  State<StatementSection> createState() => _StatementSectionState();
}

class _StatementSectionState extends State<StatementSection> {
  double _pos = 50;
  bool _dragging = false;

  void _move(double dx, double width) {
    if (width <= 0) return;
    setState(() => _pos = (dx / width * 100).clamp(0.0, 100.0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);
    final lg = Bp.lg(context);

    final sliderBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.code2, size: 13, color: C.accent),
                    const SizedBox(width: 8),
                    Flexible(child: Text('WIREFRAME & ARCHITECTURE', style: mono(12, ls: 0.1))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 13, color: C.accent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('POLISHED FLUTTER BUILD', style: mono(12, color: C.accent, ls: 0.1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _slider(md),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '↔ DRAG SLIDER TO REVEAL TRANSFORMATION',
            textAlign: TextAlign.center,
            style: mono(10, color: const Color(0xFF666666), ls: 0.1),
          ),
        ),
      ],
    );

    final cards = Column(
      children: [
        _infoCard(
          LucideIcons.layers,
          'ARCHITECTURAL RIGOR',
          'Separating UI layers, domain entities, and data providers creates apps that scale effortlessly without spaghetti state dependencies.',
        ),
        const SizedBox(height: 24),
        _infoCard(
          LucideIcons.sparkles,
          'FRAME-RATE OBSESSION',
          'Optimized rebuilds, const widgets, and performant image caching ensure fluid 60/120Hz animations across both iOS and Android hardware.',
        ),
      ],
    );

    return SectionBox(
      bg: C.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(bottom: 12), child: LabelRow('THE TRANSFORMATION')),
                Text.rich(
                  TextSpan(
                    style: anton(Bp.clampVw(context, 48, 9, 144), ls: -0.01, h: 0.9),
                    children: const [
                      TextSpan(text: 'FROM IDEA.\n'),
                      TextSpan(
                        text: 'TO APP.',
                        style: TextStyle(color: C.accent),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Text(
                      'Translating complex user requirements and business logic into high-performance, visually refined Flutter mobile applications with precision architecture.',
                      style: inter(md ? 16 : 14, color: C.muted, h: 1.625),
                    ),
                  ),
                ),
              ],
            ),
          ),
          lg
              ? Grid(
                  columns: 12,
                  gap: 48,
                  align: CrossAxisAlignment.center,
                  items: [GridItem(7, sliderBlock), GridItem(5, cards)],
                )
              : Column(children: [sliderBlock, const SizedBox(height: 48), cards]),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgAlt,
        border: Border.all(color: wh(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: C.accent),
                const SizedBox(width: 12),
                Flexible(child: Text(title, style: anton(20, ls: 0.05))),
              ],
            ),
          ),
          Text(body, style: inter(12, color: C.muted, h: 1.625)),
        ],
      ),
    );
  }

  Widget _slider(bool md) {
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        return MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          onEnter: (_) => app.cursorMode.value = CursorMode.drag,
          onExit: (_) {
            app.cursorMode.value = CursorMode.normal;
            if (_dragging) setState(() => _dragging = false);
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              if (e.kind == PointerDeviceKind.mouse) {
                setState(() => _dragging = true);
                _move(e.localPosition.dx, w);
              }
            },
            onPointerMove: (e) {
              if (e.kind == PointerDeviceKind.mouse) {
                if (_dragging) _move(e.localPosition.dx, w);
              } else {
                _move(e.localPosition.dx, w);
              }
            },
            onPointerHover: (e) {
              if (_dragging) _move(e.localPosition.dx, w);
            },
            onPointerUp: (_) => setState(() => _dragging = false),
            onPointerCancel: (_) => setState(() => _dragging = false),
            child: Container(
              height: md ? 500 : 440,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: const Color(0xFF070707),
                border: Border.all(color: wh(0.1)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: _production()),
                  // wireframe layer (left masked overlay)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRect(clipper: LeftFractionClipper(_pos / 100), child: _wireframe()),
                    ),
                  ),
                  // divider line + handle
                  Positioned(
                    left: w * _pos / 100,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: IgnorePointer(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: C.accent,
                                boxShadow: [BoxShadow(color: C.accent, blurRadius: 12)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: -16,
                            top: 0,
                            bottom: 0,
                            width: 32,
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: C.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 15,
                                      offset: Offset(0, 10),
                                      spreadRadius: -3,
                                    ),
                                  ],
                                ),
                                child: const Icon(LucideIcons.sliders, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // LAYER 1: final production UI
  Widget _production() {
    Widget statCard(String label, String value, double fill) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: Border.all(color: wh(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(label, style: mono(9, color: C.muted)),
            ),
            Text(value, style: anton(20)),
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              color: const Color(0xFF202020),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill,
                child: const ColoredBox(color: C.accent, child: SizedBox.expand()),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      color: const Color(0xFF0E0E0E),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: wh(0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'SERVICEHUB MOBILE',
                          style: anton(18, ls: 0.05),
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: op(C.accent, 0.1),
                    border: Border.all(color: op(C.accent, 0.3)),
                  ),
                  child: Text('PRODUCTION RELEASE', style: mono(10, color: C.accent)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  statCard('STATE MANAGER', 'BLOC PATTERN', 0.85),
                  const SizedBox(width: 16),
                  statCard('DATA STREAM', 'FIRESTORE LIVE', 0.95),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1C1C1C), Color(0xFF121212)]),
              border: Border.all(color: wh(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Clean Architecture • Dio Interceptors • 60 FPS', style: mono(12))),
                const SizedBox(width: 8),
                Text('SHIPPED', style: anton(14, color: C.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // LAYER 2: blueprint wireframe
  Widget _wireframe() {
    Widget box(String label, String text) => Expanded(
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(color: op(C.blue, 0.4)),
        child: Container(
          padding: const EdgeInsets.all(16),
          color: op(C.blue, 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(label, style: mono(9, color: C.blue)),
              ),
              Text(text, style: mono(14, color: wh(0.8))),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 4,
                  width: double.infinity,
                  child: CustomPaint(
                    foregroundPainter: DashedBorderPainter(
                      color: op(C.blue, 0.3),
                      top: false,
                      left: false,
                      right: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF060A10),
        border: Border(right: BorderSide(color: C.blue)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BlueGridPainter())),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: op(C.blue, 0.2))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: op(C.blue, 0.2),
                                border: Border.all(color: C.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'FRAME // WIREFRAME_01',
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: mono(14, color: C.blue, ls: 0.05),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: op(C.blue, 0.3))),
                        child: Text('SPECIFICATION', style: mono(10, color: C.blue)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          box('[CONTAINER: REPOSITORY]', 'domain/usecases/'),
                          const SizedBox(width: 16),
                          box('[DATA SOURCE: REST]', 'data/datasources/'),
                        ],
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  foregroundPainter: DashedBorderPainter(color: op(C.blue, 0.3)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('W: 1080px • H: 2400px • ASYNC DART', style: mono(12, color: C.blue)),
                        ),
                        const SizedBox(width: 8),
                        Text('DRAFT 0.9', style: mono(12, color: C.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
