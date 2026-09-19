import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:system_design/index.dart';

/// The clamp, measured where it actually lands: on a token a widget reads.
///
/// `SdBreakpointConstant` has its own unit test in the design system, and it
/// proves the arithmetic. This one proves the wiring — that the app hands
/// `ScreenUtilInit` the clamped canvas, so `SdSpacingConstant` on a tablet
/// resolves a gutter a seller can recognise instead of one scaled up by the
/// window.
void main() {
  /// The gutter as a widget under [AppScreenUtil] would resolve it on a
  /// window of [size] logical pixels.
  Future<double> gutterAt(WidgetTester tester, Size size) async {
    late double gutter;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScreenUtil(
        builder: (BuildContext context) => MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              gutter = SdSpacingConstant.w16;

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    return gutter;
  }

  group('token scale', () {
    testWidgets('a phone resolves the gutter it was drawn at', (
      WidgetTester tester,
    ) async {
      final double gutter = await gutterAt(tester, AppScreenUtil.designSize);

      expect(gutter, closeTo(16, 0.01));
    });

    testWidgets('a tablet never scales a token past the clamp', (
      WidgetTester tester,
    ) async {
      // Both orientations: the height clamp is a separate max in the same
      // call, and only one of them is exercised by a landscape window.
      for (final Size tablet in <Size>[
        const Size(834, 1194),
        const Size(1194, 834),
        const Size(1366, 1024),
      ]) {
        final double gutter = await gutterAt(tester, tablet);

        expect(
          gutter,
          lessThanOrEqualTo(16 * SdBreakpointConstant.maxTokenScale + 0.01),
          reason: '$tablet must not inflate the gutter',
        );
      }
    });

    testWidgets('the clamp is what holds it, not the window being narrow', (
      WidgetTester tester,
    ) async {
      // The guard against a green test that proves nothing: without the
      // clamp this window would resolve the gutter at well over twice the
      // drawn value.
      final double unclamped = 16 * (1366 / AppScreenUtil.designSize.width);

      expect(unclamped, greaterThan(16 * SdBreakpointConstant.maxTokenScale));
    });
  });
}
