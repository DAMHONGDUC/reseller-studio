import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/bootstrap/bootstrap.dart';
import 'seller_os_app.dart';

/// The entry point, and deliberately the smallest file in the app.
///
/// Everything that could fail lives in [bootstrap], which runs it inside a
/// guarded zone with the framework's error hooks already installed. Anything
/// added here instead would throw *outside* that zone, where nothing is
/// watching.
void main() {
  bootstrap(() => const ProviderScope(child: SellerOsApp()));
}
