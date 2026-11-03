import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'components/cursor.dart';
import 'components/footer.dart';
import 'components/grain.dart';
import 'components/navbar.dart';
import 'components/preloader.dart';
import 'components/scroll_progress.dart';
import 'core/app_controller.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'sections/about.dart';
import 'sections/contact.dart';
import 'sections/credentials.dart';
import 'sections/experience.dart';
import 'sections/hero.dart';
import 'sections/services.dart';
import 'sections/statement.dart';
import 'sections/tech_marquee.dart';
import 'sections/work.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  bool _preloaderDone = false;
  late final Ticker _scrollTicker;
  double _targetScroll = 0;
  Duration _lastScrollTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    app.scroll.addListener(_onScroll);
    _scrollTicker = createTicker(_onScrollTick);
    app.cancelWheelScroll = _cancelWheel;
  }

  void _cancelWheel() {
    if (_scrollTicker.isActive) {
      _scrollTicker.stop();
      _lastScrollTime = Duration.zero;
    }
  }

  void _onScroll() => app.onScroll(MediaQuery.sizeOf(context).height);

  void _onScrollTick(Duration elapsed) {
    if (!app.scroll.hasClients) {
      _cancelWheel();
      return;
    }
    final pos = app.scroll.position;
    final current = pos.pixels;
    final diff = _targetScroll - current;
    if (diff.abs() < 0.5) {
      app.scroll.jumpTo(_targetScroll);
      _cancelWheel();
      return;
    }
    final dt = _lastScrollTime == Duration.zero ? 1 / 60 : (elapsed - _lastScrollTime).inMicroseconds / 1e6;
    _lastScrollTime = elapsed;
    final factor = (1.0 - math.pow(0.001, math.min(dt, 0.1)).toDouble()).clamp(0.02, 0.4);
    final next = (current + diff * factor).clamp(pos.minScrollExtent, pos.maxScrollExtent).toDouble();
    app.scroll.jumpTo(next);
  }

  @override
  void dispose() {
    app.cancelWheelScroll = null;
    _scrollTicker.dispose();
    app.scroll.removeListener(_onScroll);
    super.dispose();
  }

  void _pointer(PointerEvent e) => app.pointer.value = e.position;

  /// Lenis-style smooth virtual wheel scrolling (duration 1.2s equivalent, 60/120fps continuous).
  void _wheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    if (MediaQuery.of(context).disableAnimations) return;
    if (e.scrollDelta.dy == 0 || !app.scroll.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
      final se = ev as PointerScrollEvent;
      final pos = app.scroll.position;
      final base = _scrollTicker.isActive ? _targetScroll : pos.pixels;
      _targetScroll = (base + se.scrollDelta.dy * 0.9).clamp(pos.minScrollExtent, pos.maxScrollExtent).toDouble();
      if (!_scrollTicker.isActive) {
        _lastScrollTime = Duration.zero;
        _scrollTicker.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HeroSection(),
        KeyedSubtree(key: app.key('work'), child: const WorkSection()),
        KeyedSubtree(key: app.key('skills'), child: const TechMarquee()),
        KeyedSubtree(key: app.key('credentials'), child: const CredentialsSection()),
        KeyedSubtree(key: app.key('statement'), child: const StatementSection()),
        KeyedSubtree(key: app.key('about'), child: const AboutSection()),
        KeyedSubtree(key: app.key('experience'), child: const ExperienceSection()),
        KeyedSubtree(key: app.key('services'), child: const ServicesSection()),
        KeyedSubtree(key: app.key('contact'), child: const ContactSection()),
        const Footer(),
      ],
    );

    return Scaffold(
      backgroundColor: C.bg,
      body: Listener(
        onPointerHover: _pointer,
        onPointerMove: _pointer,
        onPointerDown: _pointer,
        child: MouseRegion(
          cursor: SystemMouseCursors.none,
          child: Stack(
            children: [
              // page content (fades in once the preloader is done)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _preloaderDone ? 1 : 0,
                  duration: const Duration(milliseconds: 700),
                  curve: kTw,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          controller: app.scroll,
                          physics: const ClampingScrollPhysics(),
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerSignal: _wheel,
                            child: sections,
                          ),
                        ),
                      ),
                      const MobileMenu(),
                      const Navbar(),
                      const _CopiedToast(),
                      const Positioned.fill(child: GrainOverlay()),
                    ],
                  ),
                ),
              ),
              const ScrollProgress(),
              if (!_preloaderDone)
                Positioned.fill(
                  child: Preloader(
                    key: const ValueKey('preloader'),
                    onComplete: () {
                      app.preloaderDone.value = true;
                      setState(() => _preloaderDone = true);
                    },
                  ),
                ),
              const Positioned.fill(child: CustomCursor()),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopiedToast extends StatelessWidget {
  const _CopiedToast();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 32,
      child: IgnorePointer(
        child: ValueListenableBuilder<bool>(
          valueListenable: app.toast,
          builder: (context, show, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: show
                ? Center(
                    key: const ValueKey('toast'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: C.accent,
                        border: Border.all(color: wh(0.2)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 14, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('EMAIL COPIED TO CLIPBOARD', style: mono(12, ls: 0.1)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ),
      ),
    );
  }
}
