import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:system_design/index.dart';

/// The clamp, measured where it actually lands: on the tokens a widget reads.
///
/// `SdScreenScale` has its own unit test in the design system, and it proves
/// the arithmetic. This one proves the wiring — that the app hands
/// `ScreenUtilInit` the clamped canvas, so `SdSpacingConstant` on a tablet
/// resolves dimensions a seller can recognise instead of ones scaled up by
/// the window.
void main() {
  /// One token off each of screenutil's four ladders, as a widget under
  /// [AppScreenUtil] would resolve them on a window of [size] logical pixels.
  ///
  /// All four, because they read different ratios: `.w` and `.sp` take the
  /// width, `.h` the height, and `.r` — icons, radii, square tap targets —
  /// the smaller of the two. A clamp on one of them is not a clamp.
  Future<({double w, double h, double r, double sp})> tokensAt(
    WidgetTester tester,
    Size size,
  ) async {
    late ({double w, double h, double r, double sp}) tokens;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScreenUtil(
        builder: (BuildContext context) => MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              tokens = (
                w: SdSpacingConstant.w16,
                h: SdSpacingConstant.h16,
                r: SdSpacingConstant.r44,
                sp: SdSpacingConstant.sp14,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    return tokens;
  }

  group('token scale', () {
    testWidgets('a phone resolves the dimensions it was drawn at', (
      WidgetTester tester,
    ) async {
      final ({double w, double h, double r, double sp}) tokens = await tokensAt(
        tester,
        AppScreenUtil.designSize,
      );

      expect(tokens.w, closeTo(16, 0.01));
      expect(tokens.h, closeTo(16, 0.01));
      expect(tokens.r, closeTo(44, 0.01));
      expect(tokens.sp, closeTo(14, 0.01));
    });

    testWidgets('a tablet renders one scale, on every ladder and either way '
        'up', (WidgetTester tester) async {
      const double scale = SdScreenScale.maxScale;

      // Both orientations: the height ceiling is a separate branch of the
      // same call, and it is the one a landscape window exercises — floored
      // at a phone's design height it made `.r` draw icons and tap targets
      // smaller than the phone they were scaled up from.
      for (final Size tablet in <Size>[
        const Size(834, 1194),
        const Size(1194, 834),
        const Size(1366, 1024),
      ]) {
        final ({double w, double h, double r, double sp}) tokens =
            await tokensAt(tester, tablet);

        expect(tokens.w, closeTo(16 * scale, 0.01), reason: '$tablet gutter');
        expect(tokens.h, closeTo(16 * scale, 0.01), reason: '$tablet gap');
        expect(tokens.r, closeTo(44 * scale, 0.01), reason: '$tablet target');
        expect(tokens.sp, closeTo(14 * scale, 0.01), reason: '$tablet type');
      }
    });

    testWidgets('the clamp is what holds it, not the window being narrow', (
      WidgetTester tester,
    ) async {
      // The guard against a green test that proves nothing: without the
      // clamp this window would resolve the gutter at well over twice the
      // drawn value.
      final double unclamped = 16 * (1366 / AppScreenUtil.designSize.width);

      expect(unclamped, greaterThan(16 * SdScreenScale.maxScale));
    });
  });
}
