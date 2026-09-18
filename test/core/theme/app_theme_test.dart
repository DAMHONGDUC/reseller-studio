import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/theme/app_colors.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:system_design/index.dart';

/// The two things that silently break the whole UI, tested here because
/// nothing else would notice until a screen renders wrong:
///
/// 1. **`SdThemeV3` is registered on `ThemeData.extensions`.** Forget it and
///    every v3 widget asserts in debug and renders the neutral fallback
///    palette in release — the app would look almost right, which is worse
///    than looking broken.
/// 2. **`ScreenUtilInit` is above the widget that reads a dimension.** Every
///    `SdSpacingConstant` getter resolves at runtime, so without it the first
///    one throws.
void main() {
  /// Pumps [child] the way the real app does: screenutil installed, theme
  /// applied. A test that pumps a bare `MaterialApp` is testing a tree the
  /// app never builds.
  ///
  /// `builder:` rather than `child:` for the same reason `ResellerStudioApp` uses
  /// it: `AppTheme.light` reads `SdSpacingConstant.sp*`, so evaluating it as
  /// a constructor argument would run it before `ScreenUtilInit` has
  /// initialized and throw. This helper is the regression test for that.
  Future<void> pumpThemed(
    WidgetTester tester,
    Widget child, {
    ThemeData Function()? theme,
  }) => tester.pumpWidget(
    AppScreenUtil(
      builder: (BuildContext context) => MaterialApp(
        theme: theme == null ? AppTheme.light : theme(),
        home: child,
      ),
    ),
  );

  group('AppTheme', () {
    testWidgets('registers SdThemeV3 so v3 widgets resolve their colours', (
      WidgetTester tester,
    ) async {
      late SdThemeV3 resolved;

      await pumpThemed(
        tester,
        Builder(
          builder: (BuildContext context) {
            resolved = context.sdTheme3;

            return const SizedBox.shrink();
          },
        ),
      );

      expect(resolved.profit, AppColors.profit);
      expect(resolved.background, AppColors.background);
      // Proves the extension came from AppTheme rather than the package's
      // fallback, which would also have answered every getter.
      expect(resolved, isNot(same(SdThemeV3.fallback)));
    });

    testWidgets('dark theme swaps the palette, not just the brightness', (
      WidgetTester tester,
    ) async {
      late SdThemeV3 resolved;

      await pumpThemed(
        tester,
        Builder(
          builder: (BuildContext context) {
            resolved = context.sdTheme3;

            return const SizedBox.shrink();
          },
        ),
        theme: () => AppTheme.dark,
      );

      expect(resolved.background, AppColors.backgroundDark);
      expect(resolved.profit, AppColors.profitDark);
    });
  });

  group('status bar style', () {
    // Both platform fields are inverted with respect to each other, so an
    // eyeball on one device proves nothing about the other. These four
    // assertions are the whole guarantee.
    test('light theme asks for dark icons on both platforms', () {
      final SystemUiOverlayStyle style = AppTheme.statusBarStyle(
        Brightness.light,
      );

      // Android names the icons...
      expect(style.statusBarIconBrightness, Brightness.dark);
      // ...iOS names the background behind them.
      expect(style.statusBarBrightness, Brightness.light);
    });

    test('dark theme asks for light icons on both platforms', () {
      final SystemUiOverlayStyle style = AppTheme.statusBarStyle(
        Brightness.dark,
      );

      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.statusBarBrightness, Brightness.dark);
    });

    test('the system bars stay transparent so the body shows through', () {
      final SystemUiOverlayStyle style = AppTheme.statusBarStyle(
        Brightness.light,
      );

      expect(style.statusBarColor, Colors.transparent);
      expect(style.systemNavigationBarColor, Colors.transparent);
    });

    testWidgets('both themes carry it on the app bar theme', (
      WidgetTester tester,
    ) async {
      late ThemeData resolved;

      await pumpThemed(
        tester,
        Builder(
          builder: (BuildContext context) {
            resolved = Theme.of(context);

            return const SizedBox.shrink();
          },
        ),
        theme: () => AppTheme.dark,
      );

      // `SdAppBarV3` builds a real `AppBar`, which turns this into the
      // `AnnotatedRegion` over every route that has a bar. Unset, the style is
      // inferred from a bar colour and comes out wrong on one platform.
      expect(
        resolved.appBarTheme.systemOverlayStyle,
        AppTheme.statusBarStyle(Brightness.dark),
      );
    });
  });

  group('v3 widgets render under the app theme', () {
    testWidgets('SdStatTileV3 shows an em dash for a null value, never 0', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        const Scaffold(body: SdStatTileV3(label: 'Profit', value: null)),
      );

      // Hard rule 5: a zero is a claim, an em dash is an absence.
      expect(find.text(SdStatTileV3.emptyPlaceholder), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('SdButtonV3 keeps its size while busy', (
      WidgetTester tester,
    ) async {
      await pumpThemed(
        tester,
        Scaffold(
          body: Center(
            child: SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: 'Save',
              onPressed: () {},
            ),
          ),
        ),
      );

      final Size idle = tester.getSize(find.byType(SdButtonV3));

      await pumpThemed(
        tester,
        Scaffold(
          body: Center(
            child: SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: 'Save',
              busy: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // The spinner is drawn over the label rather than replacing it, so the
      // button cannot resize mid-tap and shift the row it sits in.
      expect(tester.getSize(find.byType(SdButtonV3)), idle);
    });
  });
}
