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
    this.premiumEmails = const <String>{},
    this.devModeEmails = const <String>{},
    this.blockedEmails = const <String>{},
  });

  /// What a client falls back to.
  ///
  /// **The flags fall back in opposite directions, and each is the safe one
  /// for what it controls.**
  ///
  /// - Monetisation falls back **on**. A failed read, a cold start with no
  ///   signal, a document nobody has created: defaulting the other way hands
  ///   the paid half of the app to everyone the first time Firestore is slow.
  /// - The forced update falls back to **not forcing**. A wrong answer here
  ///   locks every seller out of an app they cannot fix from their side, and
  ///   there is no way to ship them out of it — where a paywall shown by
  ///   mistake is cosmetic and self-corrects on the next snapshot.
  /// - Every email list falls back **empty**, which is the same direction as
  ///   the update flag read three ways: nobody is blocked out of the app,
  ///   nobody is handed a grant the owner did not type, and a config that
  ///   failed to load cannot be the reason an account is refused.
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

  /// Accounts handed Premium without buying it — the owner, the testers, a
  /// seller being made whole after a billing failure.
  ///
  /// **It is a grant, never a record of a purchase.** `subscriptionStatus`
  /// stays the honest answer to what the seller actually bought, so a screen
  /// saying so on screen reads that and not this.
  final Set<String> premiumEmails;

  /// Accounts that get the developer affordances in a **release** build —
  /// mock data and the demo seed, which are otherwise debug-only.
  final Set<String> devModeEmails;

  /// Accounts refused the app. They are sent to the blocked screen and can do
  /// nothing but sign out.
  ///
  /// **It is a UI gate, not a permission.** A blocked account still holds a
  /// valid Firebase token, so anything that must actually be refused is
  /// refused by `firestore.rules` or by disabling the account in the Firebase
  /// console. This is what stops the app being *used*, not what stops it
  /// reading.
  final Set<String> blockedEmails;

  /// Whether [build] is too old to run.
  bool forcesUpdate(int build) => build < minimumBuild;

  /// Whether this account is handed Premium by the config.
  bool grantsPremium(String? email) => _lists(premiumEmails, email);

  /// Whether this account gets the developer affordances in any build.
  bool grantsDevMode(String? email) => _lists(devModeEmails, email);

  /// Whether this account is refused the app.
  bool blocks(String? email) => _lists(blockedEmails, email);

  /// The stored lists are already lowercased by the DTO; the account's own
  /// address is lowercased here because it arrives from a vendor SDK and
  /// `Owner@Gmail.com` is the same person as `owner@gmail.com`.
  bool _lists(Set<String> emails, String? email) {
    if (email == null || email.isEmpty) return false;

    return emails.contains(email.trim().toLowerCase());
  }

  /// **Counts, never addresses.** The lists are somebody else's email and a
  /// log line is the shortest path from here to a Crashlytics dashboard
  /// (hard rule 9) — the count is what a reader needs to know the config
  /// arrived.
  Map<String, Object?> toLogData() => <String, Object?>{
    'premiumEnabled': premiumEnabled,
    'minimumBuild': minimumBuild,
    'hasUpdateUrl': updateUrl != null,
    'premiumEmails': premiumEmails.length,
    'devModeEmails': devModeEmails.length,
    'blockedEmails': blockedEmails.length,
  };
}
