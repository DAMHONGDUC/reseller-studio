import '../entities/app_config.dart';

/// Reading the product's own switches. There is no write half on purpose —
/// a client that could flip these could turn its own paywall off.
abstract interface class AppConfigRepository {
  /// The live config. Emits [AppConfig.fallback] rather than an error when it
  /// cannot be read: a seller with no signal must keep using the app, and the
  /// fallback is the safe direction.
  Stream<AppConfig> watch();
}
