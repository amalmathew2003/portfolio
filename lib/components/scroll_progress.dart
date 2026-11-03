import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/theme.dart';

class ScrollProgress extends StatelessWidget {
  const ScrollProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Positioned(
      top: 0,
      left: 0,
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: app.progress,
          builder: (context, p, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            width: w * p / 100,
            height: 2,
            decoration: const BoxDecoration(
              color: C.accent,
              boxShadow: [BoxShadow(color: C.accent, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}
