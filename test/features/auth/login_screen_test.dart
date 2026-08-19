import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/features/auth/presentation/screens/login_screen/login_screen.dart';

import '../../support/pump_app.dart';

/// **The login screen must render with Apple's mark missing** — it is the only
/// way into the app, and until the owner adds
/// `assets/brand/apple_logo.svg` there is nothing for that button to draw.
///
/// The bug this pins is not cosmetic: `SvgPicture.asset` on an absent file
/// throws while the screen builds, which takes Google — the other way in —
/// down with it. So the Apple button is hidden while its mark is, and the
/// screen still offers a way to sign in.
void main() {
  testWidgets('with no Apple mark bundled, only Google is offered', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const LoginScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
  });
}
