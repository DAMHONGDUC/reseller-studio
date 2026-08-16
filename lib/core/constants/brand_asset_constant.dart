/// Paths to the vendor brand marks bundled under `assets/brand/`.
///
/// **These files are copied from the vendor, never authored here.** Apple and
/// Google both publish their own artwork and both forbid a substitute, and an
/// approximated trademark is worse than an obvious placeholder because it
/// looks finished. `RELEASE_ACTIONS.md` blocker 5 has the download links.
///
/// A path is never typed at a call site: a renamed file that only exists as a
/// string in a widget fails at runtime, on the login screen, for every user.
final class BrandAssetConstant {
  /// Google's four-colour "G", as served by Google (`logo_googleg_48dp`).
  ///
  /// Rendered untinted — recolouring it to match the button breaches Google's
  /// branding guidelines.
  static const String googleG = 'assets/brand/google_g.svg';

  /// Apple's logo mark, from Apple's Sign in with Apple design resources.
  static const String appleLogo = 'assets/brand/apple_logo.svg';
}
