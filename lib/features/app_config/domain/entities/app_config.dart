import '../enums/app_platform.dart';
import 'app_error_notice.dart';
import 'app_update_policy.dart';

/// One switch board for the whole product, not for one business.
///
/// **It is not a workspace record** (hard rule 14 governs those): nothing here
/// belongs to a seller, and two businesses on the same build read the same
/// answer. It is the owner's remote switch, read by every client and written
/// by nobody in the app.
class AppConfig {
  const AppConfig({
    this.ios = AppUpdatePolicy.none,
    this.android = AppUpdatePolicy.none,
    this.premiumEmails = const <String>{},
    this.devModeEmails = const <String>{},
    this.blockedEmails = const <String>{},
    this.errorNotice = AppErrorNotice.none,
  });

  /// What a client falls back to.
  ///
  /// **Everything falls back to the safe direction for what it controls.**
  ///
  /// - The forced update falls back to **not forcing** ([AppUpdatePolicy.none]
  ///   on both platforms). A wrong answer here locks every seller out of an
  ///   app they cannot fix from their side, and there is no way to ship them
  ///   out of it.
  /// - Every email list falls back **empty**, which is the same direction read
  ///   three ways: nobody is blocked out of the app, nobody is handed a grant
  ///   the owner did not type, and a config that failed to load cannot be the
  ///   reason an account is refused.
  /// - The notice falls back to **not showing** ([AppErrorNotice.none]), for
  ///   the forced update's reason exactly: a wrong answer replaces the app
  ///   with a screen nobody can leave.
  static const AppConfig fallback = AppConfig();

  /// What the App Store says about the running build.
  final AppUpdatePolicy ios;

  /// What Google Play says about the running build.
  final AppUpdatePolicy android;

  /// Accounts handed Premium without buying it — the owner, the testers, a
  /// seller being made whole after a billing failure.
  ///
  /// **It is a grant, never a record of a purchase.** `subscriptionStatus`
  /// stays the honest answer to what the seller actually bought, so a screen
  /// saying so on screen reads that and not this.
  final Set<String> premiumEmails;

  /// Accounts that get the developer affordances in a **release** build —
  /// seeding and deleting a workspace, which are otherwise debug-only.
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

  /// A screen the owner can put in front of the whole app, for the hour
  /// between a problem and a release that fixes it.
  ///
  /// **It is not about an account.** Every seller on every build sees it, the
  /// same way a forced update is about the binary rather than the person — so
  /// nothing here is matched against an email.
  final AppErrorNotice errorNotice;

  /// The policy for one store.
  AppUpdatePolicy updateFor(AppPlatform platform) => switch (platform) {
    AppPlatform.ios => ios,
    AppPlatform.android => android,
  };

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
    'ios': ios.toLogData(),
    'android': android.toLogData(),
    'premiumEmails': premiumEmails.length,
    'devModeEmails': devModeEmails.length,
    'blockedEmails': blockedEmails.length,
    'errorNotice': errorNotice.toLogData(),
  };
}
