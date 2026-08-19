import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/features/auth/presentation/screens/login_screen/login_screen.dart';

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
}
