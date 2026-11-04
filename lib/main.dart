import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app.dart';
import 'core/theme.dart';
import 'dragon_skeleton_only.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // react quickly to scroll-in-view triggers
  VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 50);
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
        // 3px red scrollbar like the original
        scrollbarTheme: ScrollbarThemeData(
          thickness: const WidgetStatePropertyAll(3),
          radius: Radius.zero,
          thumbColor: const WidgetStatePropertyAll(C.accent),
          trackColor: const WidgetStatePropertyAll(C.bg),
          thumbVisibility: const WidgetStatePropertyAll(true),
        ),
      ),
      builder: (context, child) => DragonSkeletonCursor(child: child!),
      home: const AppShell(),
    );
  }
}
