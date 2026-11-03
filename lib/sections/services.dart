import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/services.dart';

class ServicesSection extends StatefulWidget {
  const ServicesSection({super.key});

  @override
  State<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection> {
  int? _expanded = 1; // first service open by default

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);

    return SectionBox(
      bg: C.bgAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(bottom: 12), child: LabelRow('04 / CORE CAPABILITIES')),
                Text.rich(
                  TextSpan(
                    style: anton(Bp.clampVw(context, 40, 6, 96), h: 0.9),
                    children: const [
                      TextSpan(text: 'WHAT I\n'),
                      TextSpan(
                        text: 'OFFER.',
                        style: TextStyle(color: C.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: wh(0.08))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in services)
                  _ServiceRow(
                    item: item,
                    md: md,
                    expanded: _expanded == item.id,
                    onTap: () => setState(() => _expanded = _expanded == item.id ? null : item.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.item, required this.md, required this.expanded, required this.onTap});
  final Service item;
  final bool md;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hov(
      sysCursor: SystemMouseCursors.click,
      onTap: onTap,
      builder: (context, h) => Container(
        padding: EdgeInsets.symmetric(vertical: md ? 40 : 32),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: wh(0.08))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      ATxt(item.number, mono(md ? 16 : 14, color: h ? C.accent : const Color(0xFF777777))),
                      SizedBox(width: md ? 48 : 24),
                      Expanded(
                        child: ATxt(
                          item.title.toUpperCase(),
                          anton(md ? 36 : 24, color: h ? C.accent : Colors.white, ls: 0.05),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                AnimatedContainer(
                  duration: kMs300,
                  curve: kTw,
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: h ? C.accent : Colors.transparent,
                    border: Border.all(color: h ? C.accent : wh(0.12)),
                  ),
                  child: expanded
                      ? const Icon(LucideIcons.minus, size: 16, color: Colors.white)
                      : ATranslate(
                          offset: Offset(h ? 2 : 0, h ? -2 : 0),
                          child: AIcon(LucideIcons.arrowUpRight, 18, h ? Colors.white : C.muted),
                        ),
                ),
              ],
            ),
            // collapsible details (height 0 → auto, opacity 0 → 1)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: expanded ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 400),
              curve: kExpo,
              builder: (context, t, child) => ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: t.clamp(0.0, 1.0).toDouble(),
                  child: Opacity(opacity: t.clamp(0.0, 1.0).toDouble(), child: child),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 24, left: md ? 80 : 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description, style: inter(md ? 16 : 14, color: C.muted, h: 1.625)),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in item.tags)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161616),
                                    border: Border.all(color: wh(0.06)),
                                  ),
                                  child: Text(tag.toUpperCase(), style: mono(10, color: C.accent, ls: 0.05)),
                                ),
                            ],
                          ),
                        ),
                      ],
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
