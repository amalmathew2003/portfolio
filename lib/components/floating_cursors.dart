import 'package:flutter/material.dart';

import '../core/painters.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class _Cur {
  const _Cur(this.name, this.color, this.x, this.y, this.delay);
  final String name;
  final Color color;
  final double x, y, delay;
}

const _cursors = <_Cur>[
  _Cur('Flutter', Color(0xFF54C5F8), 18, 25, 0),
  _Cur('Firebase', Color(0xFFFFA000), 74, 35, 1.4),
  _Cur('BLoC', Color(0xFFE63946), 38, 65, 0.7),
  _Cur('GetX', Color(0xFFA855F7), 82, 75, 2.1),
  _Cur('Provider', Color(0xFF22C55E), 12, 80, 1.8),
  _Cur('Dio', Color(0xFFF97316), 55, 20, 2.6),
];

/// Offsets of the `multiplayerDrift` keyframes (0 / 25 / 50 / 75 / 100 %).
const _drift = <Offset>[Offset(0, 0), Offset(25, -18), Offset(-15, 28), Offset(30, 14), Offset(-12, -24)];

Offset _driftAt(double t) {
  final x = t.clamp(0.0, 1.0) * 4;
  final i = x.floor().clamp(0, 3);
  final u = Curves.easeInOut.transform(x - i); // ease-in-out between keyframes
  return Offset.lerp(_drift[i], _drift[i + 1], u)!;
}

/// Figma "multiplayer" cursors drifting around the contact section (`hidden sm:block`).
class FloatingCursors extends StatelessWidget {
  const FloatingCursors({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Bp.sm(context)) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, cons) => Stack(
              children: [
                for (final c in _cursors)
                  Positioned(
                    left: cons.maxWidth * c.x / 100,
                    top: cons.maxHeight * c.y / 100,
                    child: _MultiplayerCursor(cur: c),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiplayerCursor extends StatelessWidget {
  const _MultiplayerCursor({required this.cur});
  final _Cur cur;

  @override
  Widget build(BuildContext context) {
    return LoopAnim(
      // animation: multiplayerDrift (5 + delay)s ease-in-out (delay*0.5)s infinite alternate
      duration: Duration(milliseconds: ((5 + cur.delay) * 1000).round()),
      delay: Duration(milliseconds: (cur.delay * 0.5 * 1000).round()),
      reverse: true,
      builder: (context, t) => Transform.translate(
        offset: _driftAt(t),
        child: SizedBox(
          width: 18,
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(size: const Size(18, 22), painter: CursorArrowPainter(cur.color)),
              Positioned(
                top: 20,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cur.color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4), spreadRadius: -1),
                    ],
                  ),
                  child: Text(cur.name.toUpperCase(), softWrap: false, style: mono(10, ls: 0.05)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
