import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app.dart';
import 'core/app_controller.dart';
import 'core/theme.dart';
import 'dragon_skeleton_only.dart';
import 'hacker_loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Reduce scroll-in-view detector frequency for smoother frame budget
  VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 100);
  runApp(const AmalPortfolio());
}

class AmalPortfolio extends StatelessWidget {
  const AmalPortfolio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amal Mathew — Flutter Developer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        splashFactory: NoSplash.splashFactory,
        scrollbarTheme: ScrollbarThemeData(
          thickness: const WidgetStatePropertyAll(3),
          radius: Radius.zero,
          thumbColor: const WidgetStatePropertyAll(C.accent),
          trackColor: const WidgetStatePropertyAll(C.bg),
          thumbVisibility: const WidgetStatePropertyAll(true),
        ),
      ),
      // Dragon cursor is activated only after the loading+transition fully complete
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: app.preloaderDone,
          builder: (_, isDone, __) =>
              isDone ? DragonSkeletonCursor(child: child!) : child!,
        );
      },
      home: const _HackerGate(),
    );
  }
}

/// Shows the HackerLoadingScreen first; on completion navigates to AppShell
/// with a smooth fade+lift transition.
/// Once navigated, this widget is removed from the tree entirely.
class _HackerGate extends StatefulWidget {
  const _HackerGate();

  @override
  State<_HackerGate> createState() => _HackerGateState();
}

class _HackerGateState extends State<_HackerGate> {
  bool _done = false; // set true the moment onFinished fires

  void _onFinished() {
    if (_done || !mounted) return;
    setState(() => _done = true);

    // Schedule navigation after the current frame so setState can complete
    // and avoid calling Navigator inside a build / ticker callback
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        _FadeSlideRoute(page: const AppShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Once _done is true, show a plain black screen for the brief post-frame
    // gap before the route push — prevents any flicker
    if (_done) {
      return const ColoredBox(color: Color(0xFF000000));
    }

    return NameLoadingScreen(
      title: 'PORTFOLIO',
      onFinished: _onFinished,
    );
  }
}

/// Custom route: fade + gentle upward lift, 900ms easeOutExpo.
/// Uses a [RepaintBoundary] on the incoming page so the GPU treats it as a
/// single cached texture layer, eliminating layout thrash during animation.
class _FadeSlideRoute extends PageRouteBuilder {
  _FadeSlideRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 900),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final ease = CurvedAnimation(
              parent: animation,
              // easeOutExpo — fast start, decelerates smoothly
              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
            );

            final fade = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.80, curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03), // 3% upward reveal
                  end: Offset.zero,
                ).animate(ease),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.982, end: 1.0).animate(ease),
                  // GPU-cached texture: no per-frame layout during the animation
                  child: RepaintBoundary(child: child),
                ),
              ),
            );
          },
        );

  @override
  AnimationController createAnimationController() {
    final controller = super.createAnimationController();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Short delay to let the browser commit the final route frame
        // before starting dragon cursor and hero entrance animations
        Future.delayed(const Duration(milliseconds: 150), () {
          app.preloaderDone.value = true;
        });
      }
    });
    return controller;
  }
}
