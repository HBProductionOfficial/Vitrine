import 'package:flutter/animation.dart';

abstract final class Insets {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal page padding on phones; wider screens centre the content.
  static const page = 20.0;
}

abstract final class Corners {
  static const input = 10.0;
  static const button = 12.0;
  static const card = 16.0;
  static const sheet = 24.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const move = Curves.easeInOutCubic;
}

/// Width breakpoints, picked where the product grid and forms stop fitting.
abstract final class Breakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
  static const expanded = 1200.0;

  static const formMaxWidth = 440.0;
  static const contentMaxWidth = 1080.0;
}
