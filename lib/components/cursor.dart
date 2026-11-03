import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/app_controller.dart';
import '../core/theme.dart';

bool get isTouchPlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.fuchsia;

/// Custom red dot + lagging ring cursor (desktop / mouse only).
class CustomCursor extends StatefulWidget {
  const CustomCursor({super.key});

  @override
  State<CustomCursor> createState() => _CustomCursorState();
}

class _CustomCursorState extends State<CustomCursor> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<Offset> _ring = ValueNotifier(const Offset(-100, -100));
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // lerp factor 0.1 per 60 fps frame, made frame-rate independent
    final f = 1 - math.pow(0.9, dt * 60).toDouble();
    final m = app.pointer.value;
    final r = _ring.value;
    _ring.value = Offset(r.dx + (m.dx - r.dx) * f, r.dy + (m.dy - r.dy) * f);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isTouchPlatform || MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: ValueListenableBuilder<CursorMode>(
        valueListenable: app.cursorMode,
        builder: (context, mode, _) {
          final dotSize = mode == CursorMode.normal ? 10.0 : 16.0;
          final ringSize = (mode == CursorMode.view || mode == CursorMode.drag)
              ? 80.0
              : mode == CursorMode.hover
              ? 56.0
              : 36.0;
          final ringBorder = mode != CursorMode.normal ? C.accent : wh(0.5);
          final showLabel = mode == CursorMode.view || mode == CursorMode.drag;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Ring (z 9998)
              Positioned(
                left: 0,
                top: 0,
                child: ValueListenableBuilder<Offset>(
                  valueListenable: _ring,
                  builder: (context, p, child) => Transform.translate(
                    offset: p,
                    child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: child),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.ease,
                    width: ringSize,
                    height: ringSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: showLabel ? const Color.fromRGBO(230, 57, 70, 0.1) : Colors.transparent,
                      border: Border.all(color: ringBorder, width: 1.5),
                    ),
                    child: showLabel
                        ? Text(
                            mode == CursorMode.view ? 'VIEW' : 'DRAG',
                            style: anton(12, ls: 0.05, h: 1.0).copyWith(decoration: TextDecoration.none),
                          )
                        : null,
                  ),
                ),
              ),
              // Dot (z 9999)
              Positioned(
                left: 0,
                top: 0,
                child: ValueListenableBuilder<Offset>(
                  valueListenable: app.pointer,
                  builder: (context, p, child) => Transform.translate(
                    offset: p,
                    child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: child),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.ease,
                    width: dotSize,
                    height: dotSize,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: C.accent),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
