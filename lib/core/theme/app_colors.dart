import 'package:flutter/material.dart';

/// Seller OS's palette. **The design system does not own this** — the package
/// declares colour *slots* (`SdThemeV3`) and this app fills them in, which is
/// why `packages/system_design` never names a colour and why BaroEase can
/// render the same widgets in a completely different scheme.
///
/// Two full palettes ship, light and dark, because the app is used in two
/// places that could not be more different: a bright thrift store at midday
/// and a bedroom at 1am packing orders. Light is the default — a business
/// tool that opens dark reads as an entertainment app.
///
/// Nothing outside this file writes a `Color(0x…)`. A screen that needs a
/// colour reads `context.sdTheme3` or `context.colorScheme3`.
abstract final class AppColors {
  // --- Brand ---

  /// The action colour: primary buttons, selected tabs, focused inputs.
  /// A deep indigo — deliberately not green, so it never competes with the
  /// profit colour, which is the one green that should mean something.
  static const Color brand = Color(0xFF3D50DF);
  static const Color brandDark = Color(0xFF8792FF);
  static const Color onBrand = Color(0xFFFFFFFF);
  static const Color onBrandDark = Color(0xFF0A0D1F);

  /// The tonal fill behind a secondary button.
  static const Color brandContainer = Color(0xFFE4E7FD);
  static const Color brandContainerDark = Color(0xFF262B4D);
  static const Color onBrandContainer = Color(0xFF1B2470);
  static const Color onBrandContainerDark = Color(0xFFD6DAFF);

  // --- Light surfaces ---

  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceModal = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFEDEFF3);
  static const Color border = Color(0xFFDDE1E8);
  static const Color divider = Color(0xFFEDEFF3);

  // --- Dark surfaces ---

  static const Color backgroundDark = Color(0xFF0E1116);
  static const Color surfaceDark = Color(0xFF171B22);
  static const Color surfaceModalDark = Color(0xFF12161C);
  static const Color surfaceElevatedDark = Color(0xFF222731);
  static const Color surfaceSunkenDark = Color(0xFF0A0D12);
  static const Color borderDark = Color(0xFF2A303B);
  static const Color dividerDark = Color(0xFF20252E);

  // --- Text ---

  static const Color textPrimary = Color(0xFF11151C);
  static const Color textSecondary = Color(0xFF5B6472);
  static const Color textTertiary = Color(0xFF8D96A4);

  static const Color textPrimaryDark = Color(0xFFF2F4F8);
  static const Color textSecondaryDark = Color(0xFFA3ACBB);
  static const Color textTertiaryDark = Color(0xFF6E7887);

  // --- Money ---
  //
  // Kept apart from the status accents on purpose: a $0 profit is not a
  // failure and a refund is not an error, so tinting money with success/danger
  // would say something the number does not. See SdThemeV3's class doc.

  static const Color profit = Color(0xFF0F7A57);
  static const Color profitDark = Color(0xFF43C79A);
  static const Color loss = Color(0xFFB8342A);
  static const Color lossDark = Color(0xFFFF7A70);

  // --- Status accents ---

  static const Color success = Color(0xFF0F7A57);
  static const Color successDark = Color(0xFF43C79A);
  static const Color warning = Color(0xFFA96A00);
  static const Color warningDark = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFB8342A);
  static const Color dangerDark = Color(0xFFFF7A70);
  static const Color info = Color(0xFF2160C4);
  static const Color infoDark = Color(0xFF6DA4FF);

  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color onDangerDark = Color(0xFF3A0906);

  // --- Charts ---

  static const Color chartGrid = Color(0xFFE4E7EC);
  static const Color chartGridDark = Color(0xFF262C36);

  /// The categorical series colours, in order. Analytics assigns them by
  /// index — marketplace 1, marketplace 2 — so the same platform keeps the
  /// same colour across every chart on the screen.
  ///
  /// Six, not more: past six a reader stops telling series apart by colour
  /// and needs a label anyway, so a seventh marketplace goes into "Other".
  static const List<Color> chartSeries = <Color>[
    Color(0xFF3D50DF),
    Color(0xFF0F7A57),
    Color(0xFFA96A00),
    Color(0xFF8E3BC0),
    Color(0xFF2160C4),
    Color(0xFFB8342A),
  ];

  static const List<Color> chartSeriesDark = <Color>[
    Color(0xFF8792FF),
    Color(0xFF43C79A),
    Color(0xFFE8A33D),
    Color(0xFFC48BEA),
    Color(0xFF6DA4FF),
    Color(0xFFFF7A70),
  ];

  // --- Scrim ---

  static const Color barrier = Color(0x99000000);
}
