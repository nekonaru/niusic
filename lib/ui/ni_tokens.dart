import 'package:flutter/material.dart';

/// Brand tokens for Niusic. Widgets should use these aliases instead of raw
/// hex values so theme changes stay in one place.
abstract final class NiColors {
  static const Color primary = Color(0xFF1E1B4B);
  static const Color secondary = Color(0xFF4338CA);
  static const Color accent = Color(0xFF22C55E);
  static const Color background = Color(0xFF0F0F23);
  static const Color foreground = Color(0xFFF8FAFC);
  static const Color card = Color(0xFF1B1B30);
  static const Color muted = Color(0xFF27273B);
  static const Color mutedForeground = Color(0xFF94A3B8);
  static const Color border = Color(0xFF312E81);
  static const Color danger = Color(0xFFEF4444);
}

abstract final class NiSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class NiRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

/// Premium motion constants. Durations stay short for responsive feedback and
/// longer for context changes. Reduced motion replaces them with 80ms fades.
abstract final class NiMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration button = Duration(milliseconds: 160);
  static const Duration card = Duration(milliseconds: 260);
  static const Duration sheet = Duration(milliseconds: 320);
  static const Duration page = Duration(milliseconds: 420);
  static const Duration hero = Duration(milliseconds: 480);
  static const Duration reduced = Duration(milliseconds: 80);

  static const Cubic emphasized = Cubic(0.05, 0.7, 0.1, 1);
  static const Cubic standard = Cubic(0.2, 0, 0, 1);
  static const Cubic accelerate = Cubic(0.3, 0, 1, 1);

  static Duration of(bool reduceMotion, Duration duration) =>
      reduceMotion ? reduced : duration;
}

/// Minimum touch target on Android.
const double niTouchTarget = 48;
