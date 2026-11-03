import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/skills.dart';

/// Two infinitely scrolling rows of tools (left / right), paused on hover.
class TechMarquee extends StatelessWidget {
  const TechMarquee({super.key});

  @override
  Widget build(BuildContext context) {
    final row1 = [...marqueeItems, ...marqueeItems];
    final rev = marqueeItems.reversed.toList();
    final row2 = [...rev, ...rev];
    final md = Bp.md(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: C.bg,
        border: Border.symmetric(horizontal: BorderSide(color: wh(0.06))),
      ),
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text('BUILT WITH THESE TOOLS', style: sectionLabel())),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'FULL LIFECYCLE STACK',
                        textAlign: TextAlign.right,
                        style: mono(10, color: const Color(0xFF555555), ls: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _MarqueeRow(items: row1, seconds: 28, reverse: false, base: C.muted, md: md),
          const SizedBox(height: 16),
          _MarqueeRow(items: row2, seconds: 32, reverse: true, base: const Color(0xFF777777), md: md),
        ],
      ),
    );
  }
}

class _MarqueeRow extends StatefulWidget {
  const _MarqueeRow({
    required this.items,
    required this.seconds,
    required this.reverse,
    required this.base,
    required this.md,
  });
  final List<MarqueeItem> items;
  final int seconds;
  final bool reverse;
  final Color base;
  final bool md;

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow> {
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _paused = true),
      onExit: (_) => setState(() => _paused = false),
      child: ClipRect(
        child: LoopAnim(
          duration: Duration(seconds: widget.seconds),
          paused: _paused,
          builder: (context, t) {
            final v = widget.reverse ? 1 - t : t;
            return SizedBox(
              height: widget.md ? 60 : 56,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: FractionalTranslation(
                  translation: Offset(-0.5 * v, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        _MarqueeItemView(item: widget.items[i], base: widget.base, md: widget.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarqueeItemView extends StatelessWidget {
  const _MarqueeItemView({required this.item, required this.base, required this.md});
  final MarqueeItem item;
  final Color base;
  final bool md;

  @override
  Widget build(BuildContext context) {
    return Hov(
      sysCursor: SystemMouseCursors.basic,
      builder: (context, h) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: h ? 1.0 : 0.0),
              duration: kMs150,
              builder: (context, s, child) => ColorFiltered(colorFilter: _saturation(s), child: child),
              child: Text(item.icon, style: const TextStyle(fontSize: 24, height: 1.3333)),
            ),
            const SizedBox(width: 16),
            ATxt(
              item.name.toUpperCase(),
              anton(md ? 30 : 24, color: h ? C.accent : base, ls: 0.05),
              duration: kMs300,
              softWrap: false,
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text('•', style: mono(12, color: const Color(0xFF333333))),
            ),
          ],
        ),
      ),
    );
  }

  /// grayscale(1) → grayscale(0)
  ColorFilter _saturation(double s) {
    final inv = 1 - s;
    const r = 0.2126, g = 0.7152, b = 0.0722;
    return ColorFilter.matrix(<double>[
      r * inv + s, g * inv, b * inv, 0, 0, //
      r * inv, g * inv + s, b * inv, 0, 0,
      r * inv, g * inv, b * inv + s, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
}
