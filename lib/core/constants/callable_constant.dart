/// Every Cloud Function this app calls by name.
///
/// The names have to match `functions/src/index.ts` exactly — a typo is not a
/// compile error, it is a `not-found` at the moment a seller taps the button.
/// One list here is what makes the app's whole server surface readable in one
/// file, the same reason `AppEnv` owns every env key.
final class CallableConstant {
  /// Deletes the caller's account, the businesses they solely own, and the
  /// Storage objects under them. See `functions/src/account/deleteAccount.ts`.
  static const String deleteAccount = 'deleteAccount';

  /// Deletes one business and everything under it, leaving the account and
  /// any other business alone. See `functions/src/workspace/deleteWorkspace.ts`.
  static const String deleteWorkspace = 'deleteWorkspace';
}
