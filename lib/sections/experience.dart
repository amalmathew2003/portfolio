import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/experience.dart';

class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);

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
                const Padding(padding: EdgeInsets.only(bottom: 12), child: LabelRow('03 / PROFESSIONAL HISTORY')),
                Text.rich(
                  TextSpan(
                    style: anton(Bp.clampVw(context, 40, 6, 96), h: 0.9),
                    children: const [
                      TextSpan(text: "WHERE I'VE\n"),
                      TextSpan(
                        text: 'SHIPPED WORK.',
                        style: TextStyle(color: C.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          InView(
            threshold: 0.15,
            builder: (context, inView) => Padding(
              padding: EdgeInsets.only(left: md ? 40 : 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // growing timeline line
                  Positioned(
                    left: md ? -40 : -24,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: inView ? 1 : 0),
                      duration: const Duration(milliseconds: 1200),
                      curve: kExpo,
                      builder: (context, t, child) =>
                          Transform.scale(scaleY: t, alignment: Alignment.topCenter, child: child),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [C.accent, op(C.accent, 0.5), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // timeline nodes + cards
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var idx = 0; idx < experiences.length; idx++) ...[
                        if (idx > 0) const SizedBox(height: 48),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _Card(
                              entry: experiences[idx],
                              inView: inView,
                              md: md,
                              delayMs: 200 + idx * 180,
                            ),
                            Positioned(
                              left: md ? -47 : -31,
                              top: 24,
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: C.bg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: idx == 0 ? C.accent : wh(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: idx == 0
                                    ? const Ping(size: 6, color: C.accent)
                                    : Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: wh(0.4),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.entry,
    required this.inView,
    required this.md,
    required this.delayMs,
  });

  final ExperienceEntry entry;
  final bool inView;
  final bool md;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final isCurrent = entry.id == 1;

    final headLeft = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrent ? op(C.accent, 0.1) : wh(0.06),
                  border: Border.all(color: isCurrent ? op(C.accent, 0.2) : wh(0.12)),
                ),
                child: Text(
                  isCurrent ? 'CURRENT ROLE' : entry.type,
                  style: mono(10, color: isCurrent ? C.accent : C.muted, ls: 0.1),
                ),
              ),
              Text(
                isCurrent ? '~1.3 YEARS TENURE' : 'COMPLETED',
                style: mono(10, color: const Color(0xFF777777), ls: 0.05),
              ),
            ],
          ),
        ),
        Text(entry.role.toUpperCase(), style: anton(md ? 36 : 30, ls: 0.05)),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.briefcase, size: 14, color: C.accent),
              const SizedBox(width: 8),
              Flexible(child: Text(entry.company, style: mono(14))),
            ],
          ),
        ),
      ],
    );

    final headRight = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.calendar, size: 13, color: C.accent),
            const SizedBox(width: 8),
            Text(entry.period, style: mono(12, color: C.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mapPin, size: 13, color: C.accent),
            const SizedBox(width: 8),
            Text(entry.location, style: mono(12, color: C.muted)),
          ],
        ),
      ],
    );

    return Reveal(
      trigger: inView,
      dx: 25,
      duration: const Duration(milliseconds: 700),
      delay: Duration(milliseconds: delayMs),
      child: Hov(
        builder: (context, h) => AnimatedContainer(
          duration: kMs300,
          curve: kTw,
          width: double.infinity,
          padding: EdgeInsets.all(md ? 48 : 32),
          decoration: BoxDecoration(
            color: C.bgAlt,
            border: Border.all(color: h ? op(C.accent, 0.4) : wh(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 32),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: wh(0.08))),
                ),
                child: md
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: headLeft),
                          const SizedBox(width: 24),
                          headRight,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [headLeft, const SizedBox(height: 24), headRight],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('KEY RESPONSIBILITIES & CONTRIBUTIONS', style: sectionLabel()),
              ),
              for (var i = 0; i < entry.responsibilities.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                Reveal(
                  trigger: inView,
                  dy: 10,
                  duration: const Duration(milliseconds: 400),
                  delay: Duration(milliseconds: delayMs + 120 + i * 70),
                  child: Hov(
                    builder: (context, bh) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: AScale(
                            scale: bh ? 1.1 : 1,
                            child: const Icon(LucideIcons.checkCircle2, size: 16, color: C.accent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ATxt(entry.responsibilities[i], inter(14, color: bh ? Colors.white : C.muted, h: 1.625)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
