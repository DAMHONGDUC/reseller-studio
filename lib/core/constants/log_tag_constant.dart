/// Every flow this app logs under, as a constant.
///
/// `SdLogger` takes one of these first and prints it ahead of the message, so
/// a console that interleaves everything at once can be read back one flow at
/// a time:
///
/// ```text
/// Login - Signed in — {uid: 3f9…, provider: apple}
/// Order - Order saved — {orderId: ord-4}
/// ```
///
/// **A tag names the flow, never the verb.** The message already says what
/// happened ('Save category', 'Delete item'); the tag says which part of the
/// app it happened in, which is what makes filtering on `Catalog - ` return
/// the whole story rather than a third of it.
///
/// **Never type a tag at a call site.** 'Login' and 'login' are one flow to a
/// reader and two to a text filter, and the second one is the one nobody
/// finds.
final class LogTagConstant {
  // --- Core ---
  static const String bootstrap = 'Bootstrap';
  static const String firestore = 'Firestore';
  static const String failure = 'Failure';
  static const String storage = 'Storage';
  static const String navigation = 'Navigation';
  static const String analytics = 'Analytics';
  static const String photo = 'Photo';
  static const String link = 'Link';

  // --- Auth ---
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String deleteAccount = 'Delete Account';

  // --- Business ---
  static const String workspace = 'Workspace';
  static const String team = 'Team';
  static const String quickAdd = 'Quick Add';

  /// Taking a whole buying trip in — its own flow, not Quick Add's and not
  /// Sourcing's, so a session can be read back on its own.
  static const String intake = 'Intake';
  static const String item = 'Item';
  static const String catalog = 'Catalog';
  static const String scanner = 'Scanner';
  static const String order = 'Order';
  static const String offer = 'Offer';
  static const String listing = 'Listing';

  /// Connecting a platform, and correcting what it charges.
  static const String marketplace = 'Marketplace';
  static const String expense = 'Expense';
  static const String sourcing = 'Sourcing';
  static const String report = 'Report';
  static const String subscription = 'Subscription';
  static const String notification = 'Notification';

  // --- Device and development ---
  static const String settings = 'Settings';
  static const String onboarding = 'Onboarding';
  static const String mockData = 'Mock Data';
}
