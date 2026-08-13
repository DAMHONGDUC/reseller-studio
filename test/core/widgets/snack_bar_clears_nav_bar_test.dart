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

/// A snackbar must not land inside the band the glass nav bar occupies.
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

    SdSnackBarUtilsV3.success(screenContext, 'Saved');
    await tester.pumpAndSettle();

    final double screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;
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

    SdSnackBarUtilsV3.success(screenContext, 'Saved');
    await tester.pumpAndSettle();

    final double screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;

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
}
