/// What a photo is captured and stored at.
///
/// **Its own class rather than a `static const` on the controller that happens
/// to pick images.** A controller's job is the call sequence and its error
/// handling; the size a photo is worth keeping is a decision about the product,
/// and the next screen that uploads one needs the same answer.
final class PhotoConstant {
  /// How wide a photo is stored at.
  ///
  /// Enough for a marketplace listing and small enough that a seller on a
  /// phone plan is not uploading eight megabytes per item — the Storage rules
  /// cap is a backstop, not a target.
  static const double maxWidth = 1600;

  /// JPEG quality. High enough that a fabric texture survives, low enough that
  /// the file is worth the saving.
  static const int quality = 85;
}
