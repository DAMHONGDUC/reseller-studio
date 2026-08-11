import 'package:flutter/material.dart';
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
abstract final class AppTheme {
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
    ),
    textColor: AppColors.textPrimaryDark,
  );

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
  );

  static TextTheme _textTheme(Color color) => TextTheme(
    headlineLarge: TextStyle(fontSize: SdSpacingConstant.sp36, color: color),
    headlineMedium: TextStyle(fontSize: SdSpacingConstant.sp28, color: color),
    headlineSmall: TextStyle(fontSize: SdSpacingConstant.sp24, color: color),
    titleLarge: TextStyle(fontSize: SdSpacingConstant.sp22, color: color),
    titleMedium: TextStyle(fontSize: SdSpacingConstant.sp16, color: color),
    titleSmall: TextStyle(fontSize: SdSpacingConstant.sp14, color: color),
    bodyLarge: TextStyle(fontSize: SdSpacingConstant.sp16, color: color),
    bodyMedium: TextStyle(fontSize: SdSpacingConstant.sp14, color: color),
    bodySmall: TextStyle(fontSize: SdSpacingConstant.sp12, color: color),
    labelLarge: TextStyle(fontSize: SdSpacingConstant.sp16, color: color),
    labelMedium: TextStyle(fontSize: SdSpacingConstant.sp14, color: color),
    labelSmall: TextStyle(fontSize: SdSpacingConstant.sp12, color: color),
  );
}
