/// Vendor brand marks, by path.
///
/// **Every file here is copied in exactly as its owner publishes it.** Apple
/// and Google both forbid a redrawn substitute, and an approximation is worse
/// than an obvious placeholder because it looks finished. Nothing in this
/// repo authors one.
///
/// A path that has no file behind it is not listed: `SvgPicture.asset` throws
/// *while the screen builds*, and the screen that draws these is the only way
/// into the app. Apple's logo is the mark still missing — see
/// `RELEASE_ACTIONS.md` blocker 5.
final class BrandAssetConstant {
  /// Google's four-colour "G" — their own `logo_googleg_48dp` file,
  /// byte-for-byte. Never tinted: it is four colours and stays that way.
  static const String googleG = 'assets/brand/google_g.svg';
}
