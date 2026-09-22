import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/auth/presentation/screens/login_screen/login_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **The login screen must always render both ways in.** It is the only gate
/// into the app (`CLAUDE.md` hard rule 1), so anything that can throw while it
/// builds costs a seller the product entirely.
///
/// That is not hypothetical: the marks used to be vendor SVGs loaded from
/// `assets/brand/`, and the Apple file has never existed — `SvgPicture.asset`
/// threw during build and took Google down with it. Both marks are now
/// `SimpleIcons` glyphs, which are compiled into a font and cannot fail to
/// load. This pins the outcome rather than the mechanism.
void main() {
  testWidgets('both sign-in buttons render, and nothing throws', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const LoginScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('the two are one control, drawn the same', (
    WidgetTester tester,
  ) async {
    // The pair reads as one control with two options, so a difference in
    // height, mark size or gap between them reads as a bug rather than as
    // emphasis. One widget is what guarantees it — this pins that they both
    // use it, which is the part a future edit can break.
    await pumpScreen(tester, const LoginScreen());

    final Finder apple = find.widgetWithText(
      SdVendorButtonV3,
      'Continue with Apple',
    );
    final Finder google = find.widgetWithText(
      SdVendorButtonV3,
      'Continue with Google',
    );

    expect(apple, findsOneWidget);
    expect(google, findsOneWidget);
    expect(tester.getSize(apple), tester.getSize(google));
  });

  testWidgets('the mark is drawn against the label, not against the button', (
    WidgetTester tester,
  ) async {
    // What this exists to stop coming back: a mark visibly shorter than the
    // cap height of the words beside it, which is what a generic button's
    // icon scale produced.
    await pumpScreen(tester, const LoginScreen());

    final Element label = tester.element(find.text('Continue with Apple'));
    final double fontSize = (label.widget as Text).style!.fontSize ?? 0;

    expect(fontSize, greaterThan(0));
    expect(
      SdVendorButtonV3.markSizeFor(fontSize),
      greaterThan(fontSize),
      reason: 'a logo never fills its own box, so it is boxed larger',
    );
  });
}
