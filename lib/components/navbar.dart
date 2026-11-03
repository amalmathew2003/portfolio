import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_controller.dart';
import '../core/painters.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/social_links.dart';

class _NavLink {
  const _NavLink(this.label, this.id, this.index);
  final String label;
  final String id;
  final String index;
}

const _navLinks = <_NavLink>[
  _NavLink('Work', 'work', '01'),
  _NavLink('Skills', 'skills', '02'),
  _NavLink('About', 'about', '03'),
  _NavLink('Experience', 'experience', '04'),
  _NavLink('Services', 'services', '05'),
  _NavLink('Contact', 'contact', '06'),
];

void _handleNav(String id) {
  app.menuOpen.value = false;
  app.scrollToId(id);
}

/// Spring used by the shared-layout underline (stiffness 380, damping 30).
class _SpringCurve extends Curve {
  const _SpringCurve();
  static final _sim = SpringSimulation(const SpringDescription(mass: 1, stiffness: 380, damping: 30), 0, 1, 0);

  @override
  double transformInternal(double t) => t >= 1 ? 1.0 : _sim.x(t * 0.5);
}

/// Logo — `AMAL •`
class Logo extends StatelessWidget {
  const Logo({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hov(
      cursor: CursorMode.hover,
      onTap: onTap,
      builder: (context, h) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ATxt('AMAL', anton(24, color: h ? C.accent : Colors.white, ls: 0.05)),
          const SizedBox(width: 4),
          AScale(
            scale: h ? 1.25 : 1,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);
    final pad = Bp.pad(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: app.preloaderDone,
        builder: (context, ready, child) => Reveal(
          dy: -80,
          trigger: ready,
          duration: const Duration(milliseconds: 700),
          curve: kExpo,
          child: child!,
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: app.scrolled,
          builder: (context, scrolled, _) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(end: scrolled ? 12.0 : 0.0),
              duration: kMs300,
              curve: kTw,
              builder: (context, sigma, child) => ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: child,
                ),
              ),
              child: AnimatedContainer(
                duration: kMs300,
                curve: kTw,
                padding: EdgeInsets.symmetric(vertical: scrolled ? 16 : 24),
                decoration: BoxDecoration(
                  color: scrolled ? op(C.bg, 0.85) : Colors.transparent,
                  border: Border(bottom: scrolled ? BorderSide(color: wh(0.06)) : BorderSide.none),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Logo(onTap: app.scrollToTop),
                          if (md) const _NavLinks(),
                          if (md) const _LetsTalk() else const _Hamburger(),
                        ],
                      ),
                    ),
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

class _NavLinks extends StatefulWidget {
  const _NavLinks();

  @override
  State<_NavLinks> createState() => _NavLinksState();
}

class _NavLinksState extends State<_NavLinks> {
  final GlobalKey _stackKey = GlobalKey();
  final List<GlobalKey> _keys = List.generate(_navLinks.length, (_) => GlobalKey());
  Rect? _rect;

  void _measure(String active) {
    final i = _navLinks.indexWhere((l) => l.id == active);
    if (i < 0) return;
    final sb = _stackKey.currentContext?.findRenderObject();
    final bb = _keys[i].currentContext?.findRenderObject();
    if (sb is! RenderBox || bb is! RenderBox || !sb.hasSize || !bb.hasSize) return;
    final p = bb.localToGlobal(Offset.zero, ancestor: sb);
    final r = Rect.fromLTWH(p.dx, 0, bb.size.width, bb.size.height);
    if (r != _rect && mounted) setState(() => _rect = r);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: app.activeSection,
      builder: (context, active, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure(active));
        return Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _navLinks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 32),
                  KeyedSubtree(
                    key: _keys[i],
                    child: Hov(
                      cursor: CursorMode.hover,
                      onTap: () => _handleNav(_navLinks[i].id),
                      builder: (context, h) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ATxt(
                          _navLinks[i].label.toUpperCase(),
                          mono(12, color: (active == _navLinks[i].id || h) ? Colors.white : C.muted, ls: 0.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_rect != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: const _SpringCurve(),
                left: _rect!.left,
                width: _rect!.width,
                top: _rect!.bottom - 2,
                height: 2,
                child: const ColoredBox(color: C.accent),
              ),
          ],
        );
      },
    );
  }
}

class _LetsTalk extends StatelessWidget {
  const _LetsTalk();

  @override
  Widget build(BuildContext context) {
    return Hov(
      cursor: CursorMode.hover,
      onTap: () => _handleNav('contact'),
      builder: (context, h) => AnimatedContainer(
        duration: kMs300,
        curve: kTw,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: h ? C.accent : Colors.transparent,
          border: Border.all(color: C.accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ATxt("LET'S TALK", mono(12, color: h ? Colors.white : C.accent, ls: 0.2), duration: kMs300),
            const SizedBox(width: 8),
            ATranslate(
              offset: Offset(h ? 4 : 0, 0),
              child: AIcon(LucideIcons.arrowRight, 13, h ? Colors.white : C.accent, duration: kMs300),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hamburger extends StatelessWidget {
  const _Hamburger();

  @override
  Widget build(BuildContext context) {
    return Hov(
      cursor: CursorMode.hover,
      onTap: () => app.menuOpen.value = !app.menuOpen.value,
      builder: (context, h) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: wh(0.1))),
        child: ValueListenableBuilder<bool>(
          valueListenable: app.menuOpen,
          builder: (context, open, _) => Icon(open ? LucideIcons.x : LucideIcons.menu, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// Full-screen mobile menu (`md:hidden`), revealed from the top.
class MobileMenu extends StatefulWidget {
  const MobileMenu({super.key});

  @override
  State<MobileMenu> createState() => _MobileMenuState();
}

class _MobileMenuState extends State<MobileMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _t = CurvedAnimation(parent: _c, curve: kExpo);
    app.menuOpen.addListener(_sync);
  }

  void _sync() {
    if (app.menuOpen.value) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    app.menuOpen.removeListener(_sync);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Bp.md(context)) return const SizedBox.shrink();
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          if (_c.isDismissed) return const SizedBox.shrink();
          return Opacity(
            opacity: _t.value.clamp(0.0, 1.0).toDouble(),
            child: ClipRect(
              clipper: TopRevealClipper(_t.value.clamp(0.0, 1.0).toDouble()),
              child: Container(
                color: C.bg,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
                child: _content(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MENU NAVIGATION', style: sectionLabel()),
            const SizedBox(height: 8),
            for (var i = 0; i < _navLinks.length; i++) ...[
              const SizedBox(height: 24),
              Reveal(
                dx: -30,
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: 100 + i * 50),
                child: Hov(
                  cursor: CursorMode.hover,
                  onTap: () => _handleNav(_navLinks[i].id),
                  builder: (context, h) => Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: wh(0.06))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ATxt(_navLinks[i].label.toUpperCase(), anton(36, color: h ? C.accent : Colors.white, ls: 0.05)),
                        Text(_navLinks[i].index, style: mono(12, color: C.muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        Reveal(
          dy: 20,
          duration: const Duration(milliseconds: 400),
          delay: const Duration(milliseconds: 450),
          child: Container(
            padding: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: wh(0.08))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KERALA, INDIA', style: mono(12, color: C.muted)),
                    Text('AVAILABLE FOR WORK', style: mono(12, color: C.accent)),
                  ],
                ),
                const SizedBox(height: 16),
                Hov(
                  cursor: CursorMode.hover,
                  onTap: () => launchUrl(Uri.parse(SocialLinks.emailMailto)),
                  builder: (context, h) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    color: C.accent,
                    child: Text("LET'S TALK →", style: anton(18, ls: 0.05)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
