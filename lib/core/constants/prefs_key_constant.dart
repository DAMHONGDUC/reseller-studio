/// Every `shared_preferences` key the app writes, in one place.
///
/// The keys share one flat namespace, so two features picking the same string
/// is a bug that shows up as one feature silently overwriting the other's
/// setting. Collecting them here makes a collision visible at review time
/// rather than at runtime.
///
/// **A key is never typed at a call site.** `prefs.getBool('data_mode_mock')`
/// in a controller is a magic string that no rename can follow.
final class PrefsKeyConstant {
  /// Whether mock data is on. Read by `DataModeController`, which guards it
  /// again in release — a stored `true` never survives into a shipped build.
  static const String dataModeMock = 'data_mode_mock';
}
