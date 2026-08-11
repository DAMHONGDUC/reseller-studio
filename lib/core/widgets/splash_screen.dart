import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// What the app shows while the first auth check is in flight.
///
/// Deliberately almost empty. This screen is visible for a few hundred
/// milliseconds on a warm start and it must not look like a screen that
/// failed to load — no message, no spinner text, nothing that a user could
/// read and then be confused when it vanishes.
///
/// It is also the only route a signed-out user can reach without being
/// redirected to login, which is why it lives in `core/widgets` rather than
/// under `features/auth`: it belongs to the router, not to authentication.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SdScaffoldV3(body: SdLoadingV3Page());
}
