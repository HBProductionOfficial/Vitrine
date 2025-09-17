import 'dart:math' as math;

import 'package:flutter/material.dart';

/// App colours. Ink carries actions, terracotta is kept for the few moments
/// that need attention: discounts, add to cart and live device updates.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.onInk,
    required this.accent,
    required this.accentSoft,
    required this.danger,
    required this.dangerSoft,
    required this.success,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color onInk;
  final Color accent;
  final Color accentSoft;
  final Color danger;
  final Color dangerSoft;
  final Color success;

  static const light = Palette(
    background: Color(0xFFF6F3EE),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE9E3D9),
    border: Color(0xFFE2DBD1),
    ink: Color(0xFF1D1B18),
    inkSoft: Color(0xFF57524B),
    inkFaint: Color(0xFF67615A),
    onInk: Color(0xFFFFFFFF),
    accent: Color(0xFFA8411F),
    accentSoft: Color(0xFFF9EBE4),
    danger: Color(0xFFB42318),
    dangerSoft: Color(0xFFFCE9E7),
    success: Color(0xFF2A6F46),
  );

  static const dark = Palette(
    background: Color(0xFF141210),
    surface: Color(0xFF221F1B),
    surfaceMuted: Color(0xFF2E2A26),
    border: Color(0xFF39342E),
    ink: Color(0xFFF2EEE8),
    inkSoft: Color(0xFFBDB6AC),
    inkFaint: Color(0xFFA29B90),
    onInk: Color(0xFF141210),
    accent: Color(0xFFF0845C),
    accentSoft: Color(0xFF3B241A),
    danger: Color(0xFFFF8A80),
    dangerSoft: Color(0xFF3B1D1A),
    success: Color(0xFF7CC79B),
  );

  /// Picks black or white text for an arbitrary background, whichever has
  /// the higher WCAG contrast.
  static Color readableOn(Color background) {
    final lum = background.computeLuminance();
    final whiteRatio = 1.05 / (lum + 0.05);
    final blackRatio = (lum + 0.05) / 0.05;
    return whiteRatio >= blackRatio ? Colors.white : const Color(0xFF141210);
  }

  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  @override
  Palette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? onInk,
    Color? accent,
    Color? accentSoft,
    Color? danger,
    Color? dangerSoft,
    Color? success,
  }) {
    return Palette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      onInk: onInk ?? this.onInk,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      success: success ?? this.success,
    );
  }

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    return Palette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}
