/// Where the intro flow has got to.
///
/// The router branches on this, so the three cases have to be distinguishable
/// — the same shape as `WorkspaceStatus`, and for the same reason. Preferences
/// are read asynchronously, so there is a moment where the answer is not known
/// yet; showing the intro during it would flash it at a seller who finished it
/// months ago.
enum OnboardingStatus {
  /// Preferences have not been read yet. Show the splash.
  loading,

  /// Never finished on this install. Show the intro.
  pending,

  /// Finished. Go on to the login gate.
  done,
}
