import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'reseller_studio_app.dart';

/// The entry point, and deliberately the smallest file in the app.
///
/// Everything that could fail lives in [AppBootstrap], which runs it inside a
/// guarded zone with the framework's error hooks already installed. Anything
/// added here instead would throw *outside* that zone, where nothing is
/// watching.
void main() {
  AppBootstrap.init(
    () => ProviderScope(
      // The preferences the bootstrap already loaded, so the first frame is
      // drawn in the theme the seller chose rather than corrected into it.
      overrides: AppBootstrap.overrides,
      child: const ResellerStudioApp(),
    ),
  );
}
