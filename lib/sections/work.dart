import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_controller.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/projects.dart';

class WorkSection extends StatefulWidget {
  const WorkSection({super.key});

  @override
  State<WorkSection> createState() => _WorkSectionState();
}

class _WorkSectionState extends State<WorkSection> {
  final Map<int, GlobalKey> _cardKeys = {for (final p in projects) p.id: GlobalKey()};

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);

    final heading = Text.rich(
      TextSpan(
        style: anton(Bp.clampVw(context, 40, 6, 96), h: 0.9),
        children: const [
          TextSpan(text: 'WORK THAT '),
          TextSpan(text: 'SPEEDS & SPEAKS.', style: TextStyle(color: C.accent)),
        ],
      ),
    );

    final viewAll = Hov(
      cursor: CursorMode.hover,
      onTap: () => app.scrollToId('contact'),
      builder: (context, h) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ATxt('GET IN TOUCH', mono(12, color: h ? C.accent : C.muted, ls: 0.2)),
          const SizedBox(width: 8),
          ATranslate(
            offset: Offset(h ? 4 : 0, 0),
            child: AIcon(LucideIcons.arrowRight, 14, h ? C.accent : C.muted),
          ),
        ],
      ),
    );

    return SectionBox(
      bg: C.bgAlt,
      background: [
        Positioned(
          top: 48,
          right: 24,
          child: IgnorePointer(
            child: Text('01', style: anton(md ? 200 : 140, color: wh(0.02), h: 1.0)),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: md
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: _headLeft(heading)),
                      const SizedBox(width: 24),
                      viewAll,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_headLeft(heading), const SizedBox(height: 24), viewAll],
                  ),
          ),

          // ── Project Grid ───────────────────────────────────────────────────
          if (md) ...[
            // Row 1: Featured Project (Voice Notes) — Wide Hero Card
            Reveal(
              whenVisible: true,
              dy: 40,
              duration: const Duration(milliseconds: 700),
              curve: kExpo,
              child: _ProjectCard(
                key: _cardKeys[projects[0].id],
                project: projects[0],
                layout: _CardLayout.wideHero,
              ),
            ),
            const SizedBox(height: 32),
            // Row 2: Projects 2 & 3 side-by-side with guaranteed equal heights
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Reveal(
                      whenVisible: true,
                      dy: 40,
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 700),
                      curve: kExpo,
                      child: _ProjectCard(
                        key: _cardKeys[projects[1].id],
                        project: projects[1],
                        layout: _CardLayout.half,
                        stretch: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Reveal(
                      whenVisible: true,
                      dy: 40,
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 700),
                      curve: kExpo,
                      child: _ProjectCard(
                        key: _cardKeys[projects[2].id],
                        project: projects[2],
                        layout: _CardLayout.half,
                        stretch: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Mobile: all stacked naturally
            for (var i = 0; i < projects.length; i++) ...[
              if (i > 0) const SizedBox(height: 24),
              Reveal(
                whenVisible: true,
                dy: 40,
                delay: Duration(milliseconds: i * 120),
                duration: const Duration(milliseconds: 700),
                curve: kExpo,
                child: _ProjectCard(
                  key: _cardKeys[projects[i].id],
                  project: projects[i],
                  layout: _CardLayout.half,
                  stretch: false,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _headLeft(Widget heading) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(padding: EdgeInsets.only(bottom: 12), child: LabelRow('01 / SELECTED WORK')),
      heading,
    ],
  );
}

// ─── Card layout variants ────────────────────────────────────────────────────
enum _CardLayout { wideHero, half }

// ─── Project card ─────────────────────────────────────────────────────────────
class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    super.key,
    required this.project,
    required this.layout,
    this.stretch = false,
  });

  final Project project;
  final _CardLayout layout;
  final bool stretch;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _t;
  bool _h = false;

  bool get _isHero => widget.layout == _CardLayout.wideHero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _enter(_) {
    if (mounted) setState(() => _h = true);
    app.cursorMode.value = CursorMode.view;
    _ctrl.forward();
  }

  void _exit(_) {
    if (mounted) setState(() => _h = false);
    app.cursorMode.value = CursorMode.normal;
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);

    return MouseRegion(
      onEnter: _enter,
      onExit: _exit,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = _t.value;
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateX(0.012 * t)
            ..rotateY(-0.012 * t);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          clipBehavior: Clip.hardEdge,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0C),
            border: Border.all(
              color: _h ? op(C.accent, 0.45) : wh(0.08),
              width: _h ? 1.5 : 1,
            ),
          ),
          child: _isHero && md
              ? _wideLayout(context, _h, md)
              : _stackLayout(context, _h, md),
        ),
      ),
    );
  }

  // Wide hero: preview left | content right (desktop & tablet)
  Widget _wideLayout(BuildContext context, bool h, bool md) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _preview(h, md, isWide: true)),
          Container(width: 1, color: wh(0.06)),
          Expanded(flex: 4, child: _content(h, md, stretch: true)),
        ],
      ),
    );
  }

  // Stacked: preview on top | content below
  Widget _stackLayout(BuildContext context, bool h, bool md) {
    if (widget.stretch) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _preview(h, md, isWide: false),
          Expanded(child: _content(h, md, stretch: true)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _preview(h, md, isWide: false),
        _content(h, md, stretch: false),
      ],
    );
  }

  Widget _preview(bool h, bool md, {required bool isWide}) {
    final p = widget.project;
    final previewH = isWide ? 460.0 : (_isHero ? 360.0 : (md ? 280.0 : 250.0));

    return Container(
      height: previewH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF070707),
        border: isWide ? null : Border(bottom: BorderSide(color: wh(0.06))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint index watermark
          Positioned(
            right: 16,
            bottom: 8,
            child: IgnorePointer(
              child: Text(p.index, style: anton(md ? 128 : 72, color: wh(0.04), h: 1.0)),
            ),
          ),

          // Ambient glow behind phone on hover
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: h ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [op(C.accent, 0.08), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Phone mockup with screenshot
          ATranslate(
            offset: Offset(0, h ? -10 : 0),
            duration: const Duration(milliseconds: 500),
            child: AScale(
              scale: h ? 1.06 : 1,
              duration: const Duration(milliseconds: 500),
              child: _PhoneMockup(image: p.image, title: p.title, h: h, md: md),
            ),
          ),

          // Accent sweep bar at bottom
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            height: 3,
            child: LayoutBuilder(
              builder: (context, c) => AnimatedAlign(
                alignment: Alignment.centerLeft,
                duration: Duration.zero,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  width: h ? c.maxWidth : 0,
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [C.accent, Color(0xFFFF6B7A)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(bool h, bool md, {required bool stretch}) {
    final p = widget.project;
    return Padding(
      padding: EdgeInsets.all(md ? 32 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // index + category badge
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${p.index} / ${p.subtitle}'.toUpperCase(),
                    style: mono(11, color: C.accent, ls: 0.15, bold: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: op(C.accent, 0.08),
                    border: Border.all(color: op(C.accent, 0.2)),
                  ),
                  child: Text(
                    p.categories.first.toUpperCase(),
                    style: mono(9, color: C.accent, ls: 0.05),
                  ),
                ),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ATxt(
              p.title.toUpperCase(),
              anton(md ? 32 : 26, color: h ? C.accent : Colors.white, ls: -0.02),
              duration: kMs300,
              maxLines: 1,
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              p.description,
              style: inter(13, color: C.muted, h: 1.65),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in p.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    border: Border.all(color: wh(0.1)),
                  ),
                  child: Text(tag.toUpperCase(), style: mono(9, color: C.muted, ls: 0.05)),
                ),
            ],
          ),

          if (stretch) const Spacer() else const SizedBox(height: 24),

          // CTA row (pinned to the bottom)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: wh(0.07)))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hov(
                  cursor: CursorMode.hover,
                  opaque: false,
                  onTap: () {
                    if (p.github != null) {
                      launchUrl(Uri.parse(p.github!), mode: LaunchMode.externalApplication);
                    }
                  },
                  builder: (context, bh) => Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ATxt(
                        'VIEW PROJECT',
                        mono(12, color: (h || bh) ? C.accent : Colors.white, ls: 0.1),
                        duration: kMs300,
                      ),
                      const SizedBox(width: 8),
                      ATranslate(
                        offset: Offset((h || bh) ? 4 : 0, 0),
                        child: AIcon(LucideIcons.arrowRight, 14, (h || bh) ? C.accent : Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (p.github != null) _iconLink(LucideIcons.gitBranch, p.github!),
                if (p.demo != null) ...[const SizedBox(width: 8), _iconLink(LucideIcons.externalLink, p.demo!)],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconLink(IconData icon, String url) => Hov(
    cursor: CursorMode.hover,
    opaque: false,
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    builder: (context, bh) => Padding(
      padding: const EdgeInsets.all(4),
      child: AIcon(icon, 16, bh ? Colors.white : C.muted, duration: kMs200),
    ),
  );
}

// ─── Phone mockup widget ──────────────────────────────────────────────────────
class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.image, required this.title, required this.h, required this.md});
  final String image;
  final String title;
  final bool h;
  final bool md;

  @override
  Widget build(BuildContext context) {
    final w = md ? 200.0 : 170.0;
    final height = md ? 260.0 : 220.0;

    return Container(
      width: w,
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: wh(0.14), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 60,
            offset: const Offset(0, 30),
            spreadRadius: -10,
          ),
          if (h)
            BoxShadow(
              color: C.accent.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Screenshot
            Image.asset(
              image,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
            // Notch
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 56,
                height: 8,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Screen sheen
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [wh(0.07), Colors.transparent, wh(0.02)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(LucideIcons.smartphone, size: 28, color: C.accent),
      const SizedBox(height: 10),
      Text(title.toUpperCase(), textAlign: TextAlign.center, style: anton(14, ls: 0.05)),
      const SizedBox(height: 4),
      Text('FLUTTER APP', style: mono(9, color: C.muted, ls: 0.1)),
    ],
  );
}
