/// Every `shared_preferences` key the app writes, in one place.
///
/// The keys share one flat namespace, so two features picking the same string
/// is a bug that shows up as one feature silently overwriting the other's
/// setting. Collecting them here makes a collision visible at review time
/// rather than at runtime.
///
/// **A key is never typed at a call site.** `prefs.getBool('onboarding_seen')`
/// in a controller is a magic string that no rename can follow.
final class PrefsKeyConstant {
  /// Whether the intro flow has been got through once.
  ///
  /// Device-local on purpose: it is about this install, not this account, so
  /// it belongs in preferences rather than on the user document. A seller who
  /// reinstalls sees the intro again, which is the right answer — nothing
  /// about their business is behind it.
  static const String onboardingSeen = 'onboarding_seen';

  /// The category and the shelf the last created item was filed under.
  ///
  /// Device-local, and remembered for the same reason the intake session asks
  /// for a source once per trip: a seller booking in twenty things from one
  /// haul picks the same bin twenty times otherwise. Prefilled on the create
  /// form only, where both pickers are on screen and one tap changes either —
  /// never on Quick Add, which shows neither field and would be filing stock
  /// somewhere the seller was never shown.
  static const String lastItemCategoryId = 'last_item_category_id';

  static const String lastItemLocationId = 'last_item_location_id';

  /// Which environment the last launch ran as — `dev`, `staging`, `prod`.
  ///
  /// Read by `AppFreshInstall` before anything else on the device is trusted.
  /// Two flavours sharing a bundle id share this store, so it is the only
  /// record of whose data is sitting here — and it is written *after* a wipe,
  /// never before, because the wipe clears the store it lives in.
  static const String lastEnv = 'last_env';

  /// Light, dark or system. Device-local on purpose — see
  /// `ThemeModeController`.
  static const String themeMode = 'theme_mode';
}
