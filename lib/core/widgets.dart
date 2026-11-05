import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app_controller.dart';
import 'theme.dart';

// ── Easing curves used by the original CSS / framer-motion code ──────────────
const kTw = Cubic(0.4, 0.0, 0.2, 1.0); // Tailwind default `transition`
const kExpo = Cubic(0.22, 1.0, 0.36, 1.0); // ease: [0.22, 1, 0.36, 1]
const kCssEase = Cubic(0.25, 0.1, 0.25, 1.0); // CSS `ease`
const kSpring = Cubic(0.175, 0.885, 0.32, 1.275); // spring-ish overshoot
const kMs150 = Duration(milliseconds: 150);
const kMs200 = Duration(milliseconds: 200);
const kMs300 = Duration(milliseconds: 300);
const kMs400 = Duration(milliseconds: 400);
const kMs500 = Duration(milliseconds: 500);
const kMs700 = Duration(milliseconds: 700);

// ─────────────────────────────────────────────────────────────────────────────
// Reveal — fade / slide / scale-in animation (framer-motion `initial/animate`
// or `whileInView` with `viewport={{ once: true }}`)
// ─────────────────────────────────────────────────────────────────────────────
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.dx = 0,
    this.dy = 0,
    this.fromOpacity = 0,
    this.fromScale = 1,
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
    this.curve = kExpo,
    this.whenVisible = false,
    this.threshold = 0.0,
    this.trigger = true,
  });

  final Widget child;
  final double dx;
  final double dy;
  final double fromOpacity;
  final double fromScale;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  /// Start only once the widget scrolls into view (`whileInView`).
  final bool whenVisible;
  final double threshold;

  /// External trigger (used with [InView]).
  final bool trigger;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;
  final Key _vk = UniqueKey();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.duration + widget.delay;
    _c = AnimationController(vsync: this, duration: total);
    final begin = total.inMilliseconds == 0 ? 0.0 : widget.delay.inMilliseconds / total.inMilliseconds;
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(begin, 1.0, curve: widget.curve),
    );
    if (!widget.whenVisible && widget.trigger) _start();
  }

  @override
  void didUpdateWidget(covariant Reveal old) {
    super.didUpdateWidget(old);
    if (!widget.whenVisible && widget.trigger && !_started) _start();
  }

  void _start() {
    if (_started) return;
    _started = true;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        Widget w = child!;
        if (widget.fromScale != 1) {
          w = Transform.scale(scale: widget.fromScale + (1 - widget.fromScale) * t, child: w);
        }
        if (widget.dx != 0 || widget.dy != 0) {
          w = Transform.translate(offset: Offset(widget.dx * (1 - t), widget.dy * (1 - t)), child: w);
        }
        final o = (widget.fromOpacity + (1 - widget.fromOpacity) * t).clamp(0.0, 1.0).toDouble();
        return Opacity(opacity: o, child: w);
      },
    );
    if (!widget.whenVisible) return content;
    return VisibilityDetector(
      key: _vk,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > widget.threshold) _start();
      },
      child: content,
    );
  }
}

/// Reports (once) when its child has become visible — `useInView({ triggerOnce })`.
class InView extends StatefulWidget {
  const InView({super.key, required this.builder, this.threshold = 0.1});
  final Widget Function(BuildContext context, bool inView) builder;
  final double threshold;

  @override
  State<InView> createState() => _InViewState();
}

class _InViewState extends State<InView> {
  final Key _vk = UniqueKey();
  bool _inView = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _vk,
      onVisibilityChanged: (info) {
        if (!_inView && info.visibleFraction >= widget.threshold && info.visibleFraction > 0) {
          setState(() => _inView = true);
        }
      },
      child: widget.builder(context, _inView),
    );
  }
}

/// Text-reveal: child slides up from `y: '100%'` inside an `overflow:hidden` box.
class SlideUpClip extends StatefulWidget {
  const SlideUpClip({
    super.key,
    required this.child,
    required this.duration,
    this.delay = Duration.zero,
    this.curve = kExpo,
    this.trigger = true,
  });
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool trigger;

  @override
  State<SlideUpClip> createState() => _SlideUpClipState();
}

class _SlideUpClipState extends State<SlideUpClip> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.duration + widget.delay;
    _c = AnimationController(vsync: this, duration: total);
    final begin = total.inMilliseconds == 0 ? 0.0 : widget.delay.inMilliseconds / total.inMilliseconds;
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(begin, 1.0, curve: widget.curve),
    );
    if (widget.trigger) {
      _started = true;
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SlideUpClip old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !_started) {
      _started = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, 1 - (_started ? _t.value : 0)),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Looping animation helper (`repeat: Infinity`, CSS `infinite`)
// ─────────────────────────────────────────────────────────────────────────────
class LoopAnim extends StatefulWidget {
  const LoopAnim({
    super.key,
    required this.duration,
    required this.builder,
    this.reverse = false,
    this.delay = Duration.zero,
    this.paused = false,
  });
  final Duration duration;
  final Duration delay;
  final bool reverse; // ping-pong (CSS `alternate`)
  final bool paused;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<LoopAnim> createState() => _LoopAnimState();
}

class _LoopAnimState extends State<LoopAnim> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _run();
    } else {
      Future.delayed(widget.delay, () {
        if (!_disposed && !widget.paused) _run();
      });
    }
  }

  void _run() => _c.repeat(reverse: widget.reverse);

  @override
  void didUpdateWidget(covariant LoopAnim old) {
    super.didUpdateWidget(old);
    if (widget.paused != old.paused) {
      if (widget.paused) {
        _c.stop();
      } else {
        _run();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _c, builder: (context, _) => widget.builder(context, _c.value));
}

/// Tailwind `animate-ping` — optimised with RepaintBoundary so the ring
/// doesn't dirty the parent layer on every frame.
class Ping extends StatelessWidget {
  const Ping({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const curve = Cubic(0, 0, 0.2, 1);
    return RepaintBoundary(
      child: LoopAnim(
        duration: const Duration(milliseconds: 1200),
        builder: (context, t) {
          final e = curve.transform(math.min(t / 0.75, 1.0));
          return Opacity(
            opacity: 1 - e,
            child: Transform.scale(
              scale: 1 + e,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hover helper (`group-hover:*`, `hover:*`) + custom cursor integration
// ─────────────────────────────────────────────────────────────────────────────
class Hov extends StatefulWidget {
  const Hov({
    super.key,
    required this.builder,
    this.cursor,
    this.onTap,
    this.sysCursor = MouseCursor.defer,
    this.opaque = true,
  });

  final Widget Function(BuildContext context, bool hovered) builder;

  /// Custom-cursor state to show while hovering (`a`, `button`, `[data-cursor]`).
  final CursorMode? cursor;
  final VoidCallback? onTap;
  final MouseCursor sysCursor;
  final bool opaque;

  @override
  State<Hov> createState() => _HovState();
}

class _HovState extends State<Hov> {
  bool _h = false;

  @override
  void dispose() {
    if (_h && widget.cursor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => app.cursorMode.value = CursorMode.normal);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sys = widget.sysCursor != MouseCursor.defer
        ? widget.sysCursor
        : (widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer);
    Widget w = MouseRegion(
      cursor: sys,
      opaque: widget.opaque,
      onEnter: (_) {
        setState(() => _h = true);
        if (widget.cursor != null) app.cursorMode.value = widget.cursor!;
      },
      onExit: (_) {
        if (mounted) setState(() => _h = false);
        if (widget.cursor != null) app.cursorMode.value = CursorMode.normal;
      },
      child: widget.builder(context, _h),
    );
    if (widget.onTap != null) {
      w = GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: w);
    }
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small animated helpers for `transition-*` utilities
// ─────────────────────────────────────────────────────────────────────────────
class ATxt extends StatelessWidget {
  const ATxt(this.text, this.style, {super.key, this.duration = kMs150, this.textAlign, this.softWrap, this.maxLines});
  final String text;
  final TextStyle style;
  final Duration duration;
  final TextAlign? textAlign;
  final bool? softWrap;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      style: style,
      duration: duration,
      curve: kTw,
      textAlign: textAlign,
      softWrap: softWrap ?? true,
      maxLines: maxLines,
      child: Text(text, textAlign: textAlign),
    );
  }
}

class AIcon extends StatelessWidget {
  const AIcon(this.icon, this.size, this.color, {super.key, this.duration = kMs150});
  final IconData icon;
  final double size;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: duration,
      curve: kTw,
      builder: (context, c, _) => Icon(icon, size: size, color: c ?? color),
    );
  }
}

class ATranslate extends StatelessWidget {
  const ATranslate({super.key, required this.offset, required this.child, this.duration = kMs150});
  final Offset offset;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(end: offset),
      duration: duration,
      curve: kTw,
      child: child,
      builder: (context, o, child) => Transform.translate(offset: o, child: child),
    );
  }
}

class AScale extends StatelessWidget {
  const AScale({
    super.key,
    required this.scale,
    required this.child,
    this.duration = kMs150,
    this.alignment = Alignment.center,
  });
  final double scale;
  final Widget child;
  final Duration duration;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: scale),
      duration: duration,
      curve: kTw,
      child: child,
      builder: (context, s, child) => Transform.scale(scale: s, alignment: alignment, child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout helpers
// ─────────────────────────────────────────────────────────────────────────────
class GridItem {
  const GridItem(this.span, this.child);
  final int span;
  final Widget child;
}

/// CSS-grid-like layout: `grid-cols-N gap-X` with `col-span-*` items, packed
/// row by row exactly like grid auto-placement.
class Grid extends StatelessWidget {
  const Grid({
    super.key,
    required this.columns,
    required this.items,
    this.gap = 0,
    this.rowGap,
    this.align = CrossAxisAlignment.start,
    this.stretch = false,
    this.width,
  });

  final int columns;
  final List<GridItem> items;
  final double gap;
  final double? rowGap;
  final CrossAxisAlignment align;
  final bool stretch;

  /// Known width (lets the grid avoid a LayoutBuilder, needed inside IntrinsicHeight).
  final double? width;

  Widget _build(double w) {
    final colW = (w - (columns - 1) * gap) / columns;
    final rows = <List<GridItem>>[];
    var cur = <GridItem>[];
    var used = 0;
    for (final it in items) {
      final s = it.span.clamp(1, columns);
      if (used + s > columns) {
        rows.add(cur);
        cur = [];
        used = 0;
      }
      cur.add(GridItem(s, it.child));
      used += s;
    }
    if (cur.isNotEmpty) rows.add(cur);

    final out = <Widget>[];
    for (var r = 0; r < rows.length; r++) {
      final cells = <Widget>[];
      for (var i = 0; i < rows[r].length; i++) {
        final it = rows[r][i];
        if (i > 0) cells.add(SizedBox(width: gap));
        cells.add(SizedBox(width: colW * it.span + gap * (it.span - 1), child: it.child));
      }
      Widget row = Row(crossAxisAlignment: stretch ? CrossAxisAlignment.stretch : align, children: cells);
      if (stretch && rows[r].length > 1) row = IntrinsicHeight(child: row);
      if (r > 0) out.add(SizedBox(height: rowGap ?? gap));
      out.add(row);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: out);
  }

  @override
  Widget build(BuildContext context) {
    if (width != null) return _build(width!);
    return LayoutBuilder(builder: (context, cons) => _build(cons.maxWidth));
  }
}

/// `<section class="bg-… py-32 px-6 md:px-12 relative overflow-hidden">` with a
/// `max-w-7xl mx-auto` inner wrapper.
class SectionBox extends StatelessWidget {
  const SectionBox({
    super.key,
    required this.bg,
    required this.child,
    this.vertical = 128,
    this.background = const [],
    this.border,
  });
  final Color bg;
  final Widget child;
  final double vertical;
  final List<Widget> background;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final pad = Bp.pad(context);
    return Container(
      decoration: BoxDecoration(color: bg, border: border),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          ...background,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: vertical),
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// `● 01 / SECTION NAME` row used above every section heading.
class LabelRow extends StatelessWidget {
  const LabelRow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: sectionLabel())),
      ],
    );
  }
}

/// `.red-dot` (with glow)
class RedDot extends StatelessWidget {
  const RedDot({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: C.accent,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: C.accent, blurRadius: 8)],
      ),
    );
  }
}

/// Stripe-free 1px bordered box helper.
BoxBorder border1(Color c) => Border.all(color: c, width: 1);

/// `position: sticky; top: X` for a column inside a grid (desktop only).
class Sticky extends StatefulWidget {
  const Sticky({super.key, required this.top, required this.areaKey, required this.child});
  final double top;
  final GlobalKey areaKey;
  final Widget child;

  @override
  State<Sticky> createState() => _StickyState();
}

class _StickyState extends State<Sticky> {
  final GlobalKey _childKey = GlobalKey();
  double _last = -1;

  double _dy() {
    final area = widget.areaKey.currentContext?.findRenderObject();
    final me = _childKey.currentContext?.findRenderObject();
    if (area is! RenderBox || me is! RenderBox || !area.hasSize || !me.hasSize || !area.attached) return 0;
    final areaTop = area.localToGlobal(Offset.zero).dy;
    final travel = math.max(0.0, area.size.height - me.size.height);
    return (widget.top - areaTop).clamp(0.0, travel).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app.scroll,
      child: KeyedSubtree(key: _childKey, child: widget.child),
      builder: (context, child) {
        final dy = _dy();
        // Skip transform if position hasn't changed (avoids compositing layer dirty)
        if ((dy - _last).abs() < 0.5) {
          return Transform.translate(offset: Offset(0, _last), child: child);
        }
        _last = dy;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}
