import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — identical to the CSS `@theme` block of the React project.
class C {
  static const bg = Color(0xFF090909);
  static const bgAlt = Color(0xFF111111);
  static const accent = Color(0xFFE63946);
  static const accentHover = Color(0xFFFF4D5A);
  static const muted = Color(0xFF9A9A9A);
  static const blue = Color(0xFF0D99FF);
}

/// Colour [c] with absolute opacity [o] (0‥1).
Color op(Color c, double o) => c.withAlpha((o * 255).round().clamp(0, 255));

/// White with opacity.
Color wh(double o) => op(Colors.white, o);

/// Tailwind's default `text-*` line-heights; falls back to the 1.5 inherited
/// from `html` for arbitrary pixel sizes such as `text-[10px]`.
double lh(double size) {
  switch (size.round()) {
    case 12:
      return 16 / 12;
    case 14:
      return 20 / 14;
    case 16:
      return 24 / 16;
    case 18:
      return 28 / 18;
    case 20:
      return 28 / 20;
    case 24:
      return 32 / 24;
    case 30:
      return 36 / 30;
    case 36:
      return 40 / 36;
    case 48:
    case 60:
    case 72:
    case 96:
    case 128:
      return 1.0;
  }
  return 1.5;
}

const _even = TextLeadingDistribution.even;

/// `font-anton` — [ls] is in `em` (e.g. 0.05 for `tracking-wider`).
TextStyle anton(double size, {Color color = Colors.white, double ls = 0, double? h}) => GoogleFonts.anton(
  fontSize: size,
  color: color,
  letterSpacing: ls * size,
  height: h ?? lh(size),
  fontWeight: FontWeight.w400,
).copyWith(leadingDistribution: _even);

/// `font-mono-custom` (Space Mono).
TextStyle mono(double size, {Color color = Colors.white, double ls = 0, double? h, bool bold = false}) =>
    GoogleFonts.spaceMono(
      fontSize: size,
      color: color,
      letterSpacing: ls * size,
      height: h ?? lh(size),
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    ).copyWith(leadingDistribution: _even);

/// Body font (Inter).
TextStyle inter(
  double size, {
  Color color = Colors.white,
  double ls = 0,
  double? h,
  FontWeight weight = FontWeight.w400,
}) => GoogleFonts.inter(
  fontSize: size,
  color: color,
  letterSpacing: ls * size,
  height: h ?? lh(size),
  fontWeight: weight,
).copyWith(leadingDistribution: _even);

/// `font-caveat`.
TextStyle caveat(double size, {Color color = Colors.white, double? h}) =>
    GoogleFonts.caveat(fontSize: size, color: color, height: h ?? lh(size)).copyWith(leadingDistribution: _even);

/// `.section-label` — note: in the original CSS this class is un-layered so its
/// colour always wins over Tailwind colour utilities (always #9A9A9A).
TextStyle sectionLabel() => mono(10, color: C.muted, ls: 0.2);

/// Tailwind breakpoints.
class Bp {
  static double w(BuildContext c) => MediaQuery.sizeOf(c).width;
  static double h(BuildContext c) => MediaQuery.sizeOf(c).height;
  static bool sm(BuildContext c) => w(c) >= 640;
  static bool md(BuildContext c) => w(c) >= 768;
  static bool lg(BuildContext c) => w(c) >= 1024;

  /// `px-6 md:px-12`
  static double pad(BuildContext c) => md(c) ? 48 : 24;

  /// Width of `max-w-7xl mx-auto` inside a section that has `px-6 md:px-12`.
  static double content(BuildContext c) {
    final avail = w(c) - pad(c) * 2;
    return avail < 1280 ? avail : 1280;
  }

  /// CSS `clamp(min, vw*pct, max)`.
  static double clampVw(BuildContext c, double min, double pct, double max) =>
      (w(c) * pct / 100).clamp(min, max).toDouble();
}
