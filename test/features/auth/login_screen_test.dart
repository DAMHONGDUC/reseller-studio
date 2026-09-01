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

  testWidgets('the two are drawn the same size and the same variant', (
    WidgetTester tester,
  ) async {
    // The pair reads as one control with two options, so a difference in
    // height between them reads as a bug rather than as emphasis.
    await pumpScreen(tester, const LoginScreen());

    final SdButtonV3 apple = tester.widget<SdButtonV3>(
      find.widgetWithText(SdButtonV3, 'Continue with Apple'),
    );
    final SdButtonV3 google = tester.widget<SdButtonV3>(
      find.widgetWithText(SdButtonV3, 'Continue with Google'),
    );

    expect(apple.size, google.size);
    // Never the app's indigo: Apple allows its button in black or white only
    // (hard rule 1).
    expect(apple.variant, SdButtonVariantV3.vendor);
    expect(google.variant, SdButtonVariantV3.vendor);
  });
}
