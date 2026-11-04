import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/skills.dart';

class _Step {
  const _Step(this.step, this.title, this.desc);
  final String step, title, desc;
}

const _steps = <_Step>[
  _Step(
    '01',
    'THE IDEA',
    'Deconstructing mobile requirements into user flows, component trees, and reactive data schemas.',
  ),
  _Step(
    '02',
    'THE PLAN',
    'Selecting optimal state management (BLoC/Provider), designing REST API contracts, and defining Clean Architecture boundaries.',
  ),
  _Step(
    '03',
    'THE BUILD',
    'Robust Dart coding with Dio interceptors, Firebase services, WebSocket handlers, and error resilience.',
  ),
  _Step(
    '04',
    'THE SHIP',
    'Memory leak profiling, frame drop elimination, and continuous delivery builds for Google Play & App Store.',
  ),
];

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lg = Bp.lg(context);

    final col1 = Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: C.bg,
        border: Border.all(color: wh(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text('EDUCATION & SKILLS', style: sectionLabel()),
          ),
          for (final group in skillCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(group.label.toUpperCase(), style: mono(11, ls: 0.05, bold: true)),
                  ),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final s in group.skills) _SkillChip(skill: s)]),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: wh(0.06))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.graduationCap, size: 15, color: C.accent),
                      const SizedBox(width: 8),
                      Text('EDUCATION', style: mono(12, color: C.accent)),
                    ],
                  ),
                ),
                Text('BACHELOR OF COMPUTER APPLICATIONS (BCA)', style: anton(18, ls: 0.025)),
                const SizedBox(height: 4),
                Text('Mahatma Gandhi University · 2021 — 2024 · Angamaly, Kerala', style: mono(12, color: const Color(0xFF777777))),
              ],
            ),
          ),
        ],
      ),
    );

    final col2 = Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: C.bg,
        border: Border.all(color: wh(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text('FROM IDEA TO FINAL BUILD', style: sectionLabel()),
          ),
          Stack(
            children: [
              Positioned(left: 16, top: 8, bottom: 24, width: 1, child: ColoredBox(color: wh(0.08))),
              Column(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (i > 0) const SizedBox(height: 32),
                    _StepRow(step: _steps[i]),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final col3 = Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: C.accent,
            boxShadow: [BoxShadow(color: Color.fromRGBO(230, 57, 70, 0.25), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.quote, size: 40, color: wh(0.3)),
              const SizedBox(height: 40),
              Text(
                '"MOBILE APPS MUST FEEL INSTANTANEOUS, INTENTIONAL, AND BULLETPROOF."',
                style: anton(24, ls: -0.025, h: 1.25),
              ),
              const SizedBox(height: 16),
              Container(width: 32, height: 2, color: wh(0.4)),
              const SizedBox(height: 12),
              Opacity(opacity: 0.8, child: Text('AMAL MATHEW • PHILOSOPHY', style: mono(10, ls: 0.1))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: C.bg,
            border: Border.all(color: wh(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LITTLE WINS.', style: anton(18, ls: 0.05)),
                  Text('BIG MEANING.', style: anton(18, color: C.accent, ls: 0.05)),
                ],
              ),
              const Icon(LucideIcons.sparkles, size: 24, color: C.accent),
            ],
          ),
        ),
      ],
    );

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
                const Padding(padding: EdgeInsets.only(bottom: 12), child: LabelRow('02 / BEHIND THE CODE')),
                Text.rich(
                  TextSpan(
                    style: anton(Bp.clampVw(context, 40, 6, 96), h: 0.9),
                    children: const [
                      TextSpan(text: 'NOT JUST CODE.\n'),
                      TextSpan(
                        text: 'A WAY OF BUILDING.',
                        style: TextStyle(color: C.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          lg
              ? Grid(columns: 12, gap: 32, items: [GridItem(4, col1), GridItem(5, col2), GridItem(3, col3)])
              : Column(children: [col1, const SizedBox(height: 32), col2, const SizedBox(height: 32), col3]),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill});
  final String skill;

  @override
  Widget build(BuildContext context) {
    return Hov(
      sysCursor: SystemMouseCursors.basic,
      builder: (context, h) => ATranslate(
        offset: Offset(0, h ? -3 : 0),
        duration: kMs200,
        child: AnimatedContainer(
          duration: kMs200,
          curve: kTw,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: h ? C.accent : const Color(0xFF141414),
            border: Border.all(color: h ? C.accent : wh(0.08)),
          ),
          child: ATxt(skill.toUpperCase(), mono(11, color: h ? Colors.white : C.muted, ls: 0.05), duration: kMs200),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Hov(
      builder: (context, h) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: kMs150,
            curve: kTw,
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: h ? C.accent : const Color(0xFF121212),
              border: Border.all(color: h ? C.accent : wh(0.1)),
            ),
            child: Text(step.step, style: anton(12, h: 1.0)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ATxt(step.title, anton(18, color: h ? C.accent : Colors.white, ls: 0.05)),
                ),
                Text(step.desc, style: inter(12, color: C.muted, h: 1.625)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
