/// Numbers the Home feature is tuned by, kept off the widgets that read them.
///
/// A row count is configuration about Recent Activity, not part of what the
/// widget *is* — so it does not live on the widget. See the constants rule in
/// `CLAUDE.md`.
final class HomeConstant {
  /// Three rows. Enough to answer "what happened since I last looked" without
  /// turning Home into a second Orders screen.
  static const int recentActivityMaxRows = 3;
}
