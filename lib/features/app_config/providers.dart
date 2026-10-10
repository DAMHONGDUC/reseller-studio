/// Riverpod wiring for `app_config` — the product's own switches.
///
/// **Every gate reads a provider here, never the repository.** A screen asking
/// Firestore directly would be a second answer to a question one provider owns.
library;

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_design/common.dart';

import '../../core/config/dev_flags.dart';
import '../../core/constants/log_tag_constant.dart';
import '../../core/providers/repository_providers.dart';
import '../auth/providers.dart';
import 'domain/entities/app_config.dart';
import 'domain/entities/app_error_notice.dart';
import 'domain/entities/app_update_policy.dart';
import 'domain/enums/app_platform.dart';

/// The live `app_config/current`, listened to again whenever the account
/// changes.
///
/// **The uid is watched for the re-listen, not for the value.** The repository
/// swallows a failed read and its stream closes, so a read denied or dropped
/// before sign-in left the whole session on [AppConfig.fallback] — the dev and
/// premium email lists only applied after a cold start. A new account is a new
/// listener; Riverpod keeps the old value while it connects.
final StreamProvider<AppConfig> appConfigProvider = StreamProvider<AppConfig>((
  Ref ref,
) {
  ref.watch(currentUidProvider);

  return ref.watch(appConfigRepositoryProvider).watch();
});

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
  final PackageInfo? info = await ref.watch(packageInfoProvider.future);

  return int.tryParse(info?.buildNumber ?? '') ?? _buildUnknown;
});

/// What this binary calls itself — `1.0.0+8`, as the platform reports it.
///
/// Null when the platform channel could not answer, which is a widget test
/// with no plugin registered as often as it is a real failure. Every reader
/// treats null as "unknown" rather than waiting: the dev tag leaves the
/// version out of its label, and [appBuildNumberProvider] forces nothing.
final FutureProvider<PackageInfo?> packageInfoProvider =
    FutureProvider<PackageInfo?>((Ref ref) async {
      try {
        return await PackageInfo.fromPlatform();
      } catch (error, stackTrace) {
        SdLogger.error(
          LogTagConstant.appConfig,
          'Could not read the package info — nothing will be forced',
          error: error,
          stackTrace: stackTrace,
        );

        return null;
      }
    });

/// What a build this app could not identify counts as: newer than any ceiling
/// anyone would set, so [forceUpdateProvider] answers `notRequired`.
const int _buildUnknown = 1 << 30;

/// Which store this binary came from, or null on anything else.
///
/// **`defaultTargetPlatform`, not `Platform.isIOS`.** It is overridable in a
/// test, where `dart:io` reports the host machine and would answer macOS. A
/// platform the config has no block for answers null, and null forces nothing.
final Provider<AppPlatform?> currentPlatformProvider = Provider<AppPlatform?>(
  (Ref ref) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppPlatform.ios,
    TargetPlatform.android => AppPlatform.android,
    _ => null,
  },
);

/// What this platform's store says about the running build.
///
/// Everything the sheet renders comes from here — the version to name, the
/// link to open — so two halves of one prompt cannot come from different
/// platforms' blocks.
final Provider<AppUpdatePolicy> currentUpdatePolicyProvider =
    Provider<AppUpdatePolicy>((Ref ref) {
      final AppPlatform? platform = ref.watch(currentPlatformProvider);

      if (platform == null) return AppUpdatePolicy.none;

      return ref.watch(_resolvedConfigProvider).updateFor(platform);
    });

/// Whether this build is too old to run.
///
/// **It has no loading state, and that is the safety property.** Every other
/// gate in the router may hold the app on the splash while it resolves; this
/// one must not, because it would then be able to stop the app from starting
/// over a config read that never arrived. Until something says otherwise the
/// build is new enough — the sheet appears the moment the answer does.
///
/// **It applies signed out too.** A forced update is about the binary, not
/// about an account, so the sheet is raised over whatever screen the app is
/// showing rather than being a route anything redirects to.
final Provider<bool> forceUpdateRequiredProvider = Provider<bool>((Ref ref) {
  final AppUpdatePolicy policy = ref.watch(currentUpdatePolicyProvider);
  final int build = ref.watch(appBuildNumberProvider).value ?? _buildUnknown;

  return policy.forcesUpdate(build);
});

/// The live config, or the fallback while it has not arrived.
///
/// Every gate below reads this rather than `appConfigProvider` directly: an
/// `AsyncValue` has three cases and a gate has two, and the fallback is the
/// answer for the other one.
final Provider<AppConfig> _resolvedConfigProvider = Provider<AppConfig>(
  (Ref ref) => ref.watch(appConfigProvider).value ?? AppConfig.fallback,
);

/// Whether this account was handed Premium by the config rather than by a
/// purchase.
///
/// **`currentPlanProvider` is the only thing that should read it.** A screen
/// asking this directly would be a second answer to "what is this seller
/// entitled to", and the gates already ask the first one.
final Provider<bool> premiumGrantedByEmailProvider = Provider<bool>(
  (Ref ref) => ref
      .watch(_resolvedConfigProvider)
      .grantsPremium(ref.watch(currentEmailProvider)),
);

/// Whether the developer affordances are available in this build, to this
/// account.
///
/// **It replaces `DevFlags.isDebugOrProfile` at every runtime call site.** A
/// list of emails is by definition a release-build grant, so the branch has to
/// survive compilation and the seeder ships. What stops a seller reaching it
/// is the config, not the compiler.
///
/// `DevFlags.verboseLogging` keeps its `const` guard — a *default* that flips
/// itself on in release is not something an email list was asked to buy.
///
/// why: see `docs/rules/DECISIONS.md` § Dev mode is granted by email
final Provider<bool> devModeEnabledProvider = Provider<bool>((Ref ref) {
  if (DevFlags.isDebugOrProfile) return true;

  return ref
      .watch(_resolvedConfigProvider)
      .grantsDevMode(ref.watch(currentEmailProvider));
});

/// Whether this account is refused the app.
///
/// **False while the config has not arrived, and false when nobody is signed
/// in** — the same direction as the forced update, for the same reason: a
/// gate that answers "yes" from a failed read locks people out of an app they
/// cannot fix from their side. The block lands a frame later instead.
final Provider<bool> accountBlockedProvider = Provider<bool>(
  (Ref ref) => ref
      .watch(_resolvedConfigProvider)
      .blocks(ref.watch(currentEmailProvider)),
);

/// The notice to put in front of the whole app, or null on a normal launch.
///
/// **Null rather than a notice with `shows` false**, so a gate reads one
/// question and cannot get the second half wrong — the two conditions that
/// make a notice real are asked here, once.
///
/// **No loading state, and it defaults to showing nothing.** Same safety
/// property as the forced update, in the same direction: a config that has
/// not arrived, failed or was mistyped leaves the app running. The notice
/// appears the moment the answer does.
final Provider<AppErrorNotice?> appErrorNoticeProvider =
    Provider<AppErrorNotice?>((Ref ref) {
      final AppErrorNotice notice = ref.watch(_resolvedConfigProvider).errorNotice;

      return notice.shows ? notice : null;
    });
