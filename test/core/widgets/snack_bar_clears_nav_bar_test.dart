import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Hands the test the context a screen would raise a message from.
///
/// The snackbar reads the floating-bar scope from its *caller's* context, so
/// a test that presents from anywhere else is not testing the real path.
class _ContextProbe extends StatelessWidget {
  const _ContextProbe({required this.onContext});

  final void Function(BuildContext context) onContext;

  @override
  Widget build(BuildContext context) {
    onContext(context);

    return const SizedBox.expand();
  }
}

/// Where a message lands, and what it does to the screen under it.
///
/// **Messages come from the top by default** (owner's rule), so the two
/// bottom-placed cases below name the placement explicitly — the nav-bar
/// clearance they pin is still live for a route that owns the top of the
/// screen.
///
/// It draws into the root overlay, above the whole app, so nothing in its own
/// build can see the bar — `SdFloatingBarScopeV3` around the shell body is the
/// only signal. Asserted on the rendered rectangle rather than on the text,
/// because a message the user cannot see still matches `find.text`.
void main() {
  tearDown(SdSnackBarUtilsV3.dismiss);

  testWidgets('inside the shell it rests above the glass bar', (
    WidgetTester tester,
  ) async {
    late BuildContext screenContext;

    await pumpScreen(
      tester,
      SdScaffoldV3(
        extendBody: true,
        body: SdFloatingBarScopeV3(
          child: _ContextProbe(
            onContext: (BuildContext context) => screenContext = context,
          ),
        ),
      ),
    );

    SdSnackBarUtilsV3.success(
      screenContext,
      'Saved',
      placement: SdSnackBarPlacementV3.bottom,
    );
    await tester.pumpAndSettle();

    final double screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final double barTop =
        screenHeight - SdContentPaddingV3.floatingBarInset(screenContext);

    // The whole point: the card's lower edge stops before the bar starts.
    expect(
      tester.getRect(find.byType(SdSnackBarCardV3)).bottom,
      lessThanOrEqualTo(barTop),
    );
  });

  testWidgets('on a pushed route it still sits on the safe area', (
    WidgetTester tester,
  ) async {
    late BuildContext screenContext;

    await pumpScreen(
      tester,
      SdScaffoldV3(
        body: _ContextProbe(
          onContext: (BuildContext context) => screenContext = context,
        ),
      ),
    );

    SdSnackBarUtilsV3.success(
      screenContext,
      'Saved',
      placement: SdSnackBarPlacementV3.bottom,
    );
    await tester.pumpAndSettle();

    final double screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // No scope, so nothing is floating over this route and the message keeps
    // the position it had before the scope existed.
    expect(
      tester.getRect(find.byType(SdSnackBarCardV3)).bottom,
      moreOrLessEquals(
        screenHeight - SdContentPaddingV3.detailBottom(screenContext),
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('by default it comes from the top', (WidgetTester tester) async {
    late BuildContext screenContext;

    await pumpScreen(
      tester,
      SdScaffoldV3(
        body: _ContextProbe(
          onContext: (BuildContext context) => screenContext = context,
        ),
      ),
    );

    SdSnackBarUtilsV3.success(screenContext, 'Saved');
    await tester.pumpAndSettle();

    final double screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(
      tester.getRect(find.byType(SdSnackBarCardV3)).top,
      lessThan(screenHeight / 2),
    );
  });

  testWidgets('and it never takes a tap from the screen under it', (
    WidgetTester tester,
  ) async {
    late BuildContext screenContext;
    int taps = 0;

    // A full-screen target under the overlay: whatever the card covers, this
    // still has to receive.
    await pumpScreen(
      tester,
      SdScaffoldV3(
        body: GestureDetector(
          // Opaque, or an empty SizedBox under it answers no hit test and the
          // tap this asserts on never lands anywhere.
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: _ContextProbe(
            onContext: (BuildContext context) => screenContext = context,
          ),
        ),
      ),
    );

    SdSnackBarUtilsV3.success(screenContext, 'Saved');
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(SdSnackBarCardV3)));
    await tester.pump();

    expect(taps, 1);
  });
}
