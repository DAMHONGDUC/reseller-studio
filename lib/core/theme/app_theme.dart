import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_design/index.dart';

import 'app_colors.dart';

/// The app's two `ThemeData`s, and the one place `SdThemeV3` is registered.
///
/// **Registering the extension is not optional.** Every v3 widget resolves its
/// colours through `context.sdTheme3`, which asserts when the extension is
/// missing — so a widget test that pumps a bare `MaterialApp` fails loudly
/// rather than rendering the fallback palette. Pump [light] or [dark].
///
/// Text styles come from the `TextTheme` here; v3 widgets read
/// `context.textTheme3` and never name a size. Sizes go through
/// `SdSpacingConstant.sp*` so they scale with screenutil like every other
/// dimension.
final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      secondaryContainer: AppColors.brandContainer,
      onSecondaryContainer: AppColors.onBrandContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.onDanger,
    ),
    sdTheme: const SdThemeV3(
      background: AppColors.background,
      surfaceModal: AppColors.surfaceModal,
      surfaceElevated: AppColors.surfaceElevated,
      surfaceSunken: AppColors.surfaceSunken,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textTertiary: AppColors.textTertiary,
      border: AppColors.border,
      divider: AppColors.divider,
      profit: AppColors.profit,
      loss: AppColors.loss,
      success: AppColors.success,
      warning: AppColors.warning,
      danger: AppColors.danger,
      info: AppColors.info,
      chartGrid: AppColors.chartGrid,
      barrier: AppColors.barrier,
      shadow: AppColors.shadow,
    ),
    textColor: AppColors.textPrimary,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brandDark,
      onPrimary: AppColors.onBrandDark,
      secondaryContainer: AppColors.brandContainerDark,
      onSecondaryContainer: AppColors.onBrandContainerDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.dangerDark,
      onError: AppColors.onDangerDark,
    ),
    sdTheme: const SdThemeV3(
      background: AppColors.backgroundDark,
      surfaceModal: AppColors.surfaceModalDark,
      surfaceElevated: AppColors.surfaceElevatedDark,
      surfaceSunken: AppColors.surfaceSunkenDark,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      textTertiary: AppColors.textTertiaryDark,
      border: AppColors.borderDark,
      divider: AppColors.dividerDark,
      profit: AppColors.profitDark,
      loss: AppColors.lossDark,
      success: AppColors.successDark,
      warning: AppColors.warningDark,
      danger: AppColors.dangerDark,
      info: AppColors.infoDark,
      chartGrid: AppColors.chartGridDark,
      barrier: AppColors.barrier,
      shadow: AppColors.shadowDark,
    ),
    textColor: AppColors.textPrimaryDark,
  );

  /// The status bar style for a resolved theme brightness.
  ///
  /// **The two platform fields are inverted, and both are set every time.**
  /// `statusBarIconBrightness` (Android) describes the *icons*;
  /// `statusBarBrightness` (iOS) describes the *background behind them*. A
  /// style that names one field looks correct on the platform it was tested on
  /// and renders invisible icons on the other.
  ///
  /// Derived from [brightness] rather than written out as two constants that
  /// can disagree with the palette they are meant to match — and therefore not
  /// a `const`, because this app follows the system theme and a device
  /// switching to light mode would otherwise keep light icons on a light bar.
  ///
  /// `statusBarColor` is Android-only and stays transparent: iOS ignores it,
  /// so painting it reads as "fixed on Android, still broken on iOS". The
  /// navigation bar goes with it — the glass tab pill floats over an
  /// edge-to-edge body, so a painted system bar behind it is a band of dead
  /// colour.
  static SystemUiOverlayStyle statusBarStyle(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required SdThemeV3 sdTheme,
    required Color textColor,
  }) => ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: sdTheme.background,
    useMaterial3: true,
    extensions: <ThemeExtension<dynamic>>[sdTheme],
    textTheme: _textTheme(textColor),
    splashFactory: InkSparkle.splashFactory,
    // The one place the status bar style is decided. `SdAppBarV3` builds a
    // real `AppBar`, which turns this into the `AnnotatedRegion` covering the
    // top of every route that has a bar; `SellerOsApp` reads it back out for
    // the routes that do not. No screen ever calls `SystemChrome`.
    appBarTheme: AppBarTheme(systemOverlayStyle: statusBarStyle(brightness)),
  );

  /// The text face used everywhere.
  static const String fontFamily = 'Inter';

  /// The optically-tuned face for large sizes only. See `pubspec.yaml`.
  static const String displayFontFamily = 'Inter Display';

  /// The type scale.
  ///
  /// **Tracking tightens as size grows, and that is the whole reason this is
  /// hand-written rather than left to Material's defaults.** Letterforms set
  /// at 28sp with the spacing that suits 14sp read as loose and unfinished;
  /// the negative tracking on the headline styles is what makes a big number
  /// look deliberate. It is also why the headlines use [displayFontFamily] —
  /// Inter Display is drawn for exactly this.
  ///
  /// Line heights go the other way: tight for headlines (a big number needs
  /// no air above it) and generous for body, where it is what makes a
  /// paragraph scannable.
  static TextTheme _textTheme(Color color) => TextTheme(
    headlineLarge: _display(
      SdSpacingConstant.sp36,
      color,
      -1.2,
      FontWeight.w700,
    ),
    headlineMedium: _display(
      SdSpacingConstant.sp28,
      color,
      -0.8,
      FontWeight.w700,
    ),
    headlineSmall: _display(
      SdSpacingConstant.sp24,
      color,
      -0.6,
      FontWeight.w700,
    ),
    titleLarge: _display(SdSpacingConstant.sp22, color, -0.4, FontWeight.w600),
    titleMedium: _text(SdSpacingConstant.sp16, color, -0.2, 1.35),
    titleSmall: _text(SdSpacingConstant.sp14, color, -0.1, 1.35),
    bodyLarge: _text(SdSpacingConstant.sp16, color, -0.1, 1.45),
    bodyMedium: _text(SdSpacingConstant.sp14, color, 0, 1.45),
    bodySmall: _text(SdSpacingConstant.sp12, color, 0, 1.4),
    labelLarge: _text(SdSpacingConstant.sp16, color, -0.1, 1.2),
    labelMedium: _text(SdSpacingConstant.sp14, color, 0, 1.2),
    // Positive tracking at the smallest size: badge and caption text is
    // usually uppercase-ish and short, and a little air keeps it legible.
    labelSmall: _text(SdSpacingConstant.sp12, color, 0.1, 1.2),
  );

  static TextStyle _display(
    double size,
    Color color,
    double tracking,
    FontWeight weight,
  ) => TextStyle(
    fontFamily: displayFontFamily,
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: tracking,
    height: 1.15,
  );

  static TextStyle _text(
    double size,
    Color color,
    double tracking,
    double height,
  ) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    color: color,
    letterSpacing: tracking,
    height: height,
  );
}
