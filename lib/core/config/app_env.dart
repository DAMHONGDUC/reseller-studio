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
final class AppEnv {
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
    defaultValue: 'Reseller Studio',
  );

  // --- Legal ---
  //
  // Owner's rule: the policy addresses are build-time configuration, not
  // constants, because a staging build points at a draft nobody has had a
  // lawyer read. See `docs/rules/ENV.md`.
  //
  // **No default on purpose.** Every other getter here falls back to
  // something usable; these two fall back to nothing, because a guessed URL
  // is a link a reviewer clicks and finds a 404 behind. Empty means the row
  // is not drawn at all, and `missingReleaseKeys` names the key.

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );

  static const String termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
  );

  /// Whether either policy address was configured.
  ///
  /// What a legal card reads to decide between drawing itself and staying
  /// out of the layout — App Store review requires both links (guideline
  /// 3.1.2), and a half-configured build should show the one it has rather
  /// than an empty card.
  static bool get hasLegalLinks =>
      privacyPolicyUrl.isNotEmpty || termsOfServiceUrl.isNotEmpty;

  // --- Development switches ---
  //
  // Raw, unguarded values. **Read them through `DevFlags`, never directly**:
  // that class ANDs each one with `!kReleaseMode`, which is what makes a
  // shipped binary immune to a mis-edited prod.json.

  /// Whether mock data starts on. Only a *default* — `DataModeController`
  /// persists the user's own choice on top of it.
  static const bool mockDataDefault = bool.fromEnvironment('MOCK_DATA_DEFAULT');

  /// Turns on `AppLogger.debug` output. Off even in debug builds unless
  /// asked for, so the console stays a story of what the app did rather than
  /// a firehose.
  static const bool verboseLogging = bool.fromEnvironment('VERBOSE_LOGGING');

  // --- Firebase ---
  //
  // **Two keys, and neither one configures the SDK.** `Firebase.initializeApp`
  // is called with no options, so the api keys, sender id and buckets come
  // from `GoogleService-Info.plist` and `google-services.json` — carrying them
  // here as well was one fact written twice, and the copy nothing read.
  //
  // - the project id is how the app tells "no backend configured" apart from
  //   "configured and unreachable" ([hasFirebaseConfig]);
  // - the iOS app id is read by `verify_flavor_config` in the beta lane and
  //   cross-checked against the installed plist, so a build cannot send its
  //   symbols to another project's Crashlytics.

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
  );

  /// Where callables are deployed. The client must name the same region the
  /// function was deployed to or every call 404s.
  static const String functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );

  // --- Sign-in ---
  //
  // Client *ids*, which are public by design — the OAuth flow shows them in a
  // browser URL. The matching secrets stay server-side.
  //
  // Google only. Apple needs nothing in the binary: the app goes through
  // `FirebaseAuth.signInWithProvider`, and the Services ID lives in the
  // Firebase console.

  static const String googleSignInClientIdIos = String.fromEnvironment(
    'GOOGLE_SIGN_IN_CLIENT_ID_IOS',
  );

  static const String googleSignInServerClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
  );

  // --- Billing (RevenueCat) ---
  //
  // **Public SDK keys**, the same category as the Firebase ids above: they
  // identify the app to RevenueCat and are protected by the store's receipt
  // verification, not by being unreadable. The secret half is the webhook
  // auth header, which only a Cloud Function ever sees (hard rule 10) — it
  // must never appear in this file.
  //
  // One key per store, because RevenueCat issues one per store and using the
  // wrong one fails at configure time rather than at purchase time.

  static const String revenueCatApiKeyIos = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
  );

  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
  );

  static const String revenueCatEntitlement = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT',
  );

  static const String revenueCatOffering = String.fromEnvironment(
    'REVENUECAT_OFFERING',
  );

  /// Whether billing was configured for **either** store.
  ///
  /// What the Subscription screen reads to tell "not set up yet" apart from
  /// "set up and the seller is on Free" — two states that look identical from
  /// an empty offerings list and want very different screens.
  static bool get hasBillingConfig => missingBillingKeys.isEmpty;

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
  static bool get hasFirebaseConfig => _isFilled(firebaseProjectId);

  /// Whether a key was actually filled in.
  ///
  /// `env.example.json` ships `<placeholder>` values and `melos run set-up`
  /// copies them verbatim, so a half-filled flavour file otherwise reads as
  /// configured and fails at the SDK instead of at the diagnostics.
  static bool _isFilled(String value) =>
      value.isNotEmpty && !(value.startsWith('<') && value.endsWith('>'));

  /// The keys that must be set for a **release** build to be shippable.
  ///
  /// Returned rather than asserted so `bootstrap` can log them all at once; a
  /// build that fails on the first missing key costs one round trip per key.
  static List<String> get missingReleaseKeys => <String>[
    if (!_isFilled(firebaseProjectId)) 'FIREBASE_PROJECT_ID',
    if (!_isFilled(firebaseAppIdIos)) 'FIREBASE_APP_ID_IOS',
    // Not a backend key, and still a blocker: App Store review wants both
    // links reachable from inside the binary (guideline 3.1.2).
    if (!_isFilled(privacyPolicyUrl)) 'PRIVACY_POLICY_URL',
    if (!_isFilled(termsOfServiceUrl)) 'TERMS_OF_SERVICE_URL',
  ];

  /// One line for the log and the Settings diagnostics card.
  ///
  /// **Names keys, never values.** Printing the config would put every id in
  /// the console and, in release, into Crashlytics (hard rule 9).
  /// The billing keys this build is missing.
  ///
  /// Named rather than counted: one blank field routes the app to
  /// `UnconfiguredSubscriptionRepository`, and an empty paywall looks the
  /// same whichever field it was.
  static List<String> get missingBillingKeys => <String>[
    // Either store key is enough — RevenueCat issues one per store and a
    // build only ever runs on one of them.
    if (!_isFilled(revenueCatApiKeyIos) && !_isFilled(revenueCatApiKeyAndroid))
      'REVENUECAT_API_KEY_IOS|REVENUECAT_API_KEY_ANDROID',
    if (!_isFilled(revenueCatEntitlement)) 'REVENUECAT_ENTITLEMENT',
    if (!_isFilled(revenueCatOffering)) 'REVENUECAT_OFFERING',
  ];

  static String get summary =>
      'flavor=${flavor.name} '
      'firebase=${hasFirebaseConfig ? firebaseProjectId : "not configured"} '
      'region=$functionsRegion '
      'billing=${hasBillingConfig ? "configured" : "not configured"}';
}
