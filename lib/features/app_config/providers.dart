/// Riverpod wiring for `app_config` — the product's own switches.
///
/// **Every gate reads [premiumEnabledProvider], never the repository.** The
/// flag decides whether the plan system applies at all, so a screen asking
/// Firestore directly would be a screen that behaves differently in mock mode.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_design/common.dart';

import '../../core/constants/log_tag_constant.dart';
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

/// The build number this binary was compiled as — the `+7` of `1.0.0+7`.
///
/// **Nothing waits on it, and that is deliberate.** It is a platform-channel
/// call, and holding the splash open until a plugin answers makes every cold
/// start hostage to one — a widget test with no channel registered never gets
/// an answer at all. Until it resolves the app counts as [_buildUnknown],
/// which forces nothing; the redirect re-runs the moment the real number
/// lands, so a build that is too old is stopped a frame later rather than not
/// at all.
///
/// A platform that cannot answer resolves to [_buildUnknown] too. Failing the
/// other way would lock a seller out over a plugin error they cannot see.
final FutureProvider<int> appBuildNumberProvider = FutureProvider<int>((
  Ref ref,
) async {
  try {
    final PackageInfo info = await PackageInfo.fromPlatform();

    return int.tryParse(info.buildNumber) ?? _buildUnknown;
  } catch (error, stackTrace) {
    SdLogger.error(
      LogTagConstant.appConfig,
      'Could not read the build number — nothing will be forced',
      error: error,
      stackTrace: stackTrace,
    );

    return _buildUnknown;
  }
});

/// What a build this app could not identify counts as: newer than any ceiling
/// anyone would set, so [forceUpdateProvider] answers `notRequired`.
const int _buildUnknown = 1 << 30;

/// Whether this build is too old to run.
///
/// **It has no loading state, and that is the safety property.** Every other
/// gate in the router may hold the app on the splash while it resolves; this
/// one must not, because it would then be able to stop the app from starting
/// over a config read that never arrived. Until something says otherwise the
/// build is new enough — the screen appears the moment the answer does.
///
/// **It applies signed out too.** A forced update is about the binary, not
/// about an account, so it sits above every other redirect (hard rule 1's
/// order is unchanged below it).
final Provider<bool> forceUpdateRequiredProvider = Provider<bool>((Ref ref) {
  final AppConfig config =
      ref.watch(appConfigProvider).value ?? AppConfig.fallback;
  final int build = ref.watch(appBuildNumberProvider).value ?? _buildUnknown;

  return config.forcesUpdate(build);
});

/// Where the forced-update screen sends the seller, or null when the config
/// names nowhere.
final Provider<String?> updateUrlProvider = Provider<String?>(
  (Ref ref) => ref.watch(appConfigProvider).value?.updateUrl,
);
