/// Riverpod wiring for `app_config` — the product's own switches.
///
/// **Every gate reads [premiumEnabledProvider], never the repository.** The
/// flag decides whether the plan system applies at all, so a screen asking
/// Firestore directly would be a screen that behaves differently in mock mode.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import 'domain/entities/app_config.dart';

final StreamProvider<AppConfig> appConfigProvider = StreamProvider<AppConfig>(
  (Ref ref) => ref.watch(appConfigRepositoryProvider).watch(),
);

/// Whether the plan system applies at all.
///
/// **Falls back to on while loading, erroring, or with no document**, which is
/// the whole of [AppConfig.fallback]'s reasoning: the other direction gives
/// the paid half of the app away on every cold start.
final Provider<bool> premiumEnabledProvider = Provider<bool>(
  (Ref ref) =>
      ref.watch(appConfigProvider).value?.premiumEnabled ??
      AppConfig.fallback.premiumEnabled,
);
