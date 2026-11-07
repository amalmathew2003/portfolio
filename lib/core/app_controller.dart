import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CursorMode { normal, hover, view, drag }

/// Global, lightweight app state (scroll, cursor, menu, toast, sections).
class AppCtrl {
  final ScrollController scroll = ScrollController();


  

  /// Position of the pointer in window coordinates (like clientX/clientY).
  final ValueNotifier<Offset> pointer = ValueNotifier(const Offset(-100, -100));
  final ValueNotifier<CursorMode> cursorMode = ValueNotifier(CursorMode.normal);

  final ValueNotifier<bool> scrolled = ValueNotifier(false);
  final ValueNotifier<double> progress = ValueNotifier(0);
  final ValueNotifier<String> activeSection = ValueNotifier('work');
  final ValueNotifier<bool> menuOpen = ValueNotifier(false);
  final ValueNotifier<bool> toast = ValueNotifier(false);
  final ValueNotifier<bool> preloaderDone = ValueNotifier(false);
  VoidCallback? cancelWheelScroll;

  final Map<String, GlobalKey> _keys = {};
  GlobalKey key(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: id));

  static const trackedSections = ['work', 'skills', 'about', 'experience', 'services', 'contact'];

  /// `element.scrollIntoView({ behavior: 'smooth' })`
  void scrollToId(String id) {
    cancelWheelScroll?.call();
    final ctx = _keys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 900), curve: Curves.easeInOutCubic);
  }

  void scrollToTop() {
    cancelWheelScroll?.call();
    if (!scroll.hasClients) return;
    scroll.animateTo(0, duration: const Duration(milliseconds: 900), curve: Curves.easeInOutCubic);
  }

  /// Updates scrolled / progress / active-section notifiers.
  void onScroll(double viewportHeight) {
    if (!scroll.hasClients) return;
    final pos = scroll.position;
    scrolled.value = pos.pixels > 40;
    final max = pos.maxScrollExtent;
    progress.value = max > 0 ? (pos.pixels / max * 100).clamp(0.0, 100.0).toDouble() : 0;

    String? best;
    double bestVis = 0;
    for (final id in trackedSections) {
      final ctx = _keys[id]?.currentContext;
      final rb = ctx?.findRenderObject();
      if (rb is! RenderBox || !rb.attached || !rb.hasSize) continue;
      final top = rb.localToGlobal(Offset.zero).dy;
      final h = rb.size.height;
      if (h <= 0) continue;
      final vis = (math.min(top + h, viewportHeight) - math.max(top, 0)).clamp(0.0, h).toDouble();
      if (vis / h >= 0.25 && vis > bestVis) {
        bestVis = vis;
        best = id;
      }
    }
    if (best != null && best != activeSection.value) activeSection.value = best;
  }

  void showCopiedToast() {
    toast.value = true;
    Future.delayed(const Duration(milliseconds: 2500), () => toast.value = false);
  }
}

final AppCtrl app = AppCtrl();
