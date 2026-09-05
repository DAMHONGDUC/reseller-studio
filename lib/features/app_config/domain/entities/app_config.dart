/// One switch board for the whole product, not for one business.
///
/// **It is not a workspace record** (hard rule 14 governs those): nothing here
/// belongs to a seller, and two businesses on the same build read the same
/// answer. It is the owner's remote switch, read by every client and written
/// by nobody in the app.
class AppConfig {
  const AppConfig({
    required this.premiumEnabled,
    required this.minimumBuild,
    this.updateUrl,
  });

  /// What a client falls back to.
  ///
  /// **The two flags fall back in opposite directions, and each is the safe
  /// one for what it controls.**
  ///
  /// - Monetisation falls back **on**. A failed read, a cold start with no
  ///   signal, a document nobody has created: defaulting the other way hands
  ///   the paid half of the app to everyone the first time Firestore is slow.
  /// - The forced update falls back to **not forcing**. A wrong answer here
  ///   locks every seller out of an app they cannot fix from their side, and
  ///   there is no way to ship them out of it — where a paywall shown by
  ///   mistake is cosmetic and self-corrects on the next snapshot.
  static const AppConfig fallback = AppConfig(
    premiumEnabled: true,
    minimumBuild: 0,
  );

  /// Whether the plan system applies at all.
  ///
  /// False turns monetisation off for **everyone**: no ceiling blocks a
  /// create, every capability is included, and nothing offers a purchase. It
  /// is one flag rather than a per-feature list because half-priced is not a
  /// state this product has.
  final bool premiumEnabled;

  /// The oldest build allowed to run. Anything below it is stopped.
  ///
  /// **A build number, never a version string.** `1.0.0+7` — the build is a
  /// monotonic integer the stores already order by, so the comparison is
  /// `<` and nothing else. A version string needs a comparator, and
  /// `1.10.0` against `1.9.0` is exactly where a hand-written one is wrong.
  ///
  /// Zero forces nothing, which is what [fallback] carries.
  final int minimumBuild;

  /// Where the seller is sent to update. Null leaves the screen without a
  /// button rather than sending them somewhere that does not exist.
  ///
  /// **Configured rather than compiled in**, because the store listing does
  /// not exist yet and because a broken link must be fixable without a
  /// release — which is the one thing a forced-update screen cannot ask for.
  final String? updateUrl;

  /// Whether [build] is too old to run.
  bool forcesUpdate(int build) => build < minimumBuild;

  Map<String, Object?> toLogData() => <String, Object?>{
    'premiumEnabled': premiumEnabled,
    'minimumBuild': minimumBuild,
    'hasUpdateUrl': updateUrl != null,
  };
}
