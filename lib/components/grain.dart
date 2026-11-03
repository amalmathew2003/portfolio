import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/painters.dart';

/// Film-grain overlay (`.grain::after`): noise at 3.5 % opacity that jitters in
/// 2 steps every 0.5 s, like the CSS `grain` keyframes.
class GrainOverlay extends StatefulWidget {
  const GrainOverlay({super.key});

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  ui.Image? _image;
  Offset _pct = Offset.zero;

  static const _keys = <Offset>[Offset(0, 0), Offset(-2, -3), Offset(3, 2), Offset(-1, 4), Offset(0, 0)];

  @override
  void initState() {
    super.initState();
    _makeNoise();
    _ticker = createTicker(_tick)..start();
  }

  Future<void> _makeNoise() async {
    const size = 256;
    final rnd = math.Random(7);
    final bytes = Uint8List(size * size * 4);
    for (var i = 0; i < size * size; i++) {
      final v = rnd.nextInt(256);
      bytes[i * 4] = v;
      bytes[i * 4 + 1] = v;
      bytes[i * 4 + 2] = v;
      bytes[i * 4 + 3] = 255;
    }
    ui.decodeImageFromPixels(bytes, size, size, ui.PixelFormat.rgba8888, (img) {
      if (mounted) setState(() => _image = img);
    });
  }

  void _tick(Duration e) {
    final t = (e.inMicroseconds % 500000) / 500000; // 0.5 s loop
    final seg = (t * 4).floor().clamp(0, 3);
    final u = t * 4 - seg;
    // steps(2): hold start value, then jump half-way, then next keyframe
    final k = u < 0.5 ? 0.0 : 0.5;
    final a = _keys[seg];
    final b = _keys[seg + 1];
    final next = Offset(a.dx + (b.dx - a.dx) * k, a.dy + (b.dy - a.dy) * k);
    if (next != _pct) setState(() => _pct = next);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) return const SizedBox.shrink();
    final s = MediaQuery.sizeOf(context);
    // the overlay is 200 % of the viewport and translated by a % of itself
    final off = Offset(_pct.dx / 100 * s.width * 2, _pct.dy / 100 * s.height * 2);
    return IgnorePointer(
      child: SizedBox.expand(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: NoisePainter(image: img, offset: off),
          ),
        ),
      ),
    );
  }
}
