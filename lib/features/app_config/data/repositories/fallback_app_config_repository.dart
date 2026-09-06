import '../../domain/entities/app_config.dart';
import '../../domain/repositories/app_config_repository.dart';

/// The config a build with no Firebase reads.
///
/// `FirebaseFirestore.instance` throws `[core/no-app]` when
/// `Firebase.initializeApp` has not run, and the config is read before the
/// first frame — so an unconfigured build needs an answer rather than a crash.
/// [AppConfig.fallback] is that answer, and it is the same one a failed read
/// falls back to, so the two paths cannot disagree.
class FallbackAppConfigRepository implements AppConfigRepository {
  const FallbackAppConfigRepository();

  @override
  Stream<AppConfig> watch() => Stream<AppConfig>.value(AppConfig.fallback);
}
