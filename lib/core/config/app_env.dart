/// Which build this is.
///
/// Drives anything that must differ between a developer's machine and a
/// shipped app *and* is not a safety property. Safety properties do not
/// belong here — see [Flavor.isProd]'s doc.
enum Flavor {
  dev,
  staging,
  prod;

  static Flavor parse(String value) => switch (value) {
    'prod' => Flavor.prod,
    'staging' => Flavor.staging,
    _ => Flavor.dev,
  };

  /// **Never gate a security decision on this.** It is a string from a JSON
  /// file that anyone can edit, so it says which config was passed, not which
  /// binary was built. `kReleaseMode` is the only trustworthy answer to "is
  /// this shipped?", and it is what `DevFlags` uses.
  bool get isProd => this == Flavor.prod;
}

/// Every build-time constant, read once, in one place.
///
/// Values come from `env/<flavour>.json` via `--dart-define-from-file`, which
/// turns each JSON entry into a compile-time environment declaration. **This
/// is the only file in the app allowed to name an env key**; everything else
/// reads a typed getter here. A `String.fromEnvironment('FIREBASE_...')`
/// scattered through features is a set of magic strings nobody can audit and
/// a typo that silently returns `''`.
///
/// Every getter has a default, so a build with no `--dart-define-from-file`
/// still compiles and runs. That is what keeps `fvm flutter test` working
/// without passing a flavour to it.
///
/// ## These values are NOT secret
///
/// `--dart-define-from-file` compiles the JSON into the binary. Anyone with
/// the `.ipa` can read every value in it. Firebase api keys and app ids are
/// fine — they are public identifiers protected by `firestore.rules`, not
/// credentials. **Marketplace OAuth secrets are not fine and must never
/// appear here** (hard rule 10): they live in Secret Manager and are read
/// only by Cloud Functions. See `env/README.md`.
abstract final class AppEnv {
  // --- Identity ---

  static const Flavor flavor = _flavor == 'prod'
      ? Flavor.prod
      : _flavor == 'staging'
      ? Flavor.staging
      : Flavor.dev;

  static const String _flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// What the app calls itself in-product. The *installed* name comes from
  /// `Info.plist` and `AndroidManifest.xml` and cannot be set from here.
  static const String appDisplayName = String.fromEnvironment(
    'APP_DISPLAY_NAME',
    defaultValue: 'Seller OS',
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@selleros.app',
  );

  // --- Development switches ---
  //
  // Raw, unguarded values. **Read them through `DevFlags`, never directly**:
  // that class ANDs each one with `!kReleaseMode`, which is what makes a
  // shipped binary immune to a mis-edited prod.json.

  static const bool bypassAuthRequested = bool.fromEnvironment('BYPASS_AUTH');

  /// Whether mock data starts on. Only a *default* — `DataModeController`
  /// persists the user's own choice on top of it.
  static const bool mockDataDefault = bool.fromEnvironment(
    'MOCK_DATA_DEFAULT',
  );

  /// Turns on `AppLogger.debug` output. Off even in debug builds unless
  /// asked for, so the console stays a story of what the app did rather than
  /// a firehose.
  static const bool verboseLogging = bool.fromEnvironment('VERBOSE_LOGGING');

  // --- Firebase ---
  //
  // Mirrors what `flutterfire configure` writes into `firebase_options.dart`.
  // Both exist on purpose: the generated file is what the SDK reads, and
  // these are what tooling and the Settings diagnostics screen read without
  // importing a gitignored file that may not exist yet.

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );

  static const String firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );

  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );

  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.dd.seller.os',
  );

  /// Where callables are deployed. The client must name the same region the
  /// function was deployed to or every call 404s.
  static const String functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'asia-southeast1',
  );

  // --- Sign-in ---
  //
  // Client *ids*, which are public by design — the OAuth flow shows them in a
  // browser URL. The matching secrets stay server-side.

  static const String googleSignInIosClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_IOS_CLIENT_ID',
  );

  static const String googleSignInServerClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
  );

  static const String appleSignInServiceId = String.fromEnvironment(
    'APPLE_SIGN_IN_SERVICE_ID',
  );

  // --- Workspace defaults ---
  //
  // What a brand-new workspace is created with, before the owner picks. Not
  // the same as *the* currency — that is per workspace and lives in Firestore
  // (`workspaceCurrencyProvider`). This is only the pre-filled value on the
  // creation form.

  static const String defaultCurrency = String.fromEnvironment(
    'DEFAULT_CURRENCY',
    defaultValue: 'USD',
  );

  static const String defaultCountry = String.fromEnvironment(
    'DEFAULT_COUNTRY',
    defaultValue: 'US',
  );

  // --- Diagnostics ---

  /// Whether a Firebase config was passed at all.
  ///
  /// What `bootstrap` checks to tell "no project configured yet" apart from
  /// "configured and the network is down" — two situations that look
  /// identical from an init failure and want different log lines.
  static bool get hasFirebaseConfig => firebaseProjectId.isNotEmpty;

  /// The keys that must be set for a **release** build to be shippable.
  ///
  /// Returned rather than asserted so `bootstrap` can log them all at once; a
  /// build that fails on the first missing key costs one round trip per key.
  static List<String> get missingReleaseKeys => <String>[
    if (firebaseProjectId.isEmpty) 'FIREBASE_PROJECT_ID',
    if (firebaseIosApiKey.isEmpty) 'FIREBASE_IOS_API_KEY',
    if (firebaseIosAppId.isEmpty) 'FIREBASE_IOS_APP_ID',
    if (firebaseAndroidApiKey.isEmpty) 'FIREBASE_ANDROID_API_KEY',
    if (firebaseAndroidAppId.isEmpty) 'FIREBASE_ANDROID_APP_ID',
    if (firebaseMessagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
    if (firebaseStorageBucket.isEmpty) 'FIREBASE_STORAGE_BUCKET',
  ];

  /// One line for the log and the Settings diagnostics card.
  ///
  /// **Names keys, never values.** Printing the config would put every id in
  /// the console and, in release, into Crashlytics (hard rule 9).
  static String get summary =>
      'flavor=${flavor.name} '
      'firebase=${hasFirebaseConfig ? firebaseProjectId : "not configured"} '
      'region=$functionsRegion';
}
