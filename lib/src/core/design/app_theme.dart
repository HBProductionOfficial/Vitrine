import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'page_transitions.dart';
import 'palette.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Palette.light, Brightness.light);
  static ThemeData dark() => _build(Palette.dark, Brightness.dark);

  // Manrope keeps price digits even and readable. google_fonts loads one file
  // per weight, so each style asks for its weight here rather than through
  // copyWith later. Georgian falls back to Noto Sans Georgian.
  static TextTheme _textTheme(Palette p) {
    TextStyle style(double size, FontWeight weight, Color color, {double? height, double? spacing}) {
      return GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      ).copyWith(
        fontFamilyFallback: [GoogleFonts.notoSansGeorgian(fontWeight: weight).fontFamily!],
      );
    }

    return TextTheme(
      headlineMedium: style(28, FontWeight.w800, p.ink, height: 1.15, spacing: -0.6),
      headlineSmall: style(22, FontWeight.w800, p.ink, spacing: -0.3),
      titleLarge: style(19, FontWeight.w700, p.ink),
      titleMedium: style(16, FontWeight.w700, p.ink),
      titleSmall: style(14, FontWeight.w700, p.ink),
      bodyLarge: style(16, FontWeight.w400, p.ink, height: 1.45),
      bodyMedium: style(14.5, FontWeight.w400, p.inkSoft, height: 1.45),
      bodySmall: style(12.5, FontWeight.w500, p.inkFaint),
      labelLarge: style(15, FontWeight.w700, p.ink),
      labelMedium: style(13, FontWeight.w600, p.inkSoft),
      labelSmall: style(11.5, FontWeight.w600, p.inkSoft),
    );
  }

  static ThemeData _build(Palette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.ink,
      onPrimary: p.onInk,
      secondary: p.accent,
      onSecondary: Palette.readableOn(p.accent),
      error: p.danger,
      onError: Palette.readableOn(p.danger),
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkSoft,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceMuted,
      surfaceContainerHighest: p.surfaceMuted,
      outline: p.border,
      outlineVariant: p.border,
    );

    final text = _textTheme(p);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Corners.input),
      borderSide: BorderSide(color: p.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: text,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: p.inkFaint),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.ink, width: 1.6)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.danger)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.danger, width: 1.6)),
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
        prefixIconColor: p.inkFaint,
        suffixIconColor: p.inkSoft,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.onInk,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.inkFaint,
          minimumSize: const Size(64, 52),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corners.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: p.border, width: 1.2),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corners.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(48, 44),
          textStyle: text.labelLarge?.copyWith(decoration: TextDecoration.underline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.ink,
        side: BorderSide(color: p.border),
        labelStyle: text.labelMedium?.copyWith(color: p.ink),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: p.onInk),
        checkmarkColor: p.onInk,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corners.input)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.surfaceMuted,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? p.ink : p.inkFaint,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? p.ink : p.inkFaint),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.surfaceMuted,
        selectedIconTheme: IconThemeData(color: p.ink),
        unselectedIconTheme: IconThemeData(color: p.inkFaint),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: p.ink),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: p.inkFaint),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        // The sheet is the one surface that floats above the page, so it is
        // the only place with a shadow.
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corners.card)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.onInk),
        actionTextColor: p.onInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corners.button)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onInk : p.inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.ink : p.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.all(p.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.ink : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(p.onInk),
        side: BorderSide(color: p.inkFaint, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.ink, linearTrackColor: p.surfaceMuted),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.inkSoft,
          selectedBackgroundColor: p.ink,
          selectedForegroundColor: p.onInk,
          side: BorderSide(color: p.border),
          textStyle: text.labelMedium,
        ),
      ),
    );
  }
}
