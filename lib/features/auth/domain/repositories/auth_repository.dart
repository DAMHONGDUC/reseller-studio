/// Who the seller signed in with.
///
/// Both ship, and Apple is not optional: App Store guideline 4.8 requires
/// Sign in with Apple wherever a third-party sign-in is offered.
enum AuthProviderKind {
  apple,
  google;

  /// Shown in Settings so a seller can see which account they are on.
  /// **Not localized** — these are brand names.
  String get displayName => switch (this) {
    AuthProviderKind.apple => 'Apple',
    AuthProviderKind.google => 'Google',
  };
}

/// The result of a sign-in attempt.
///
/// **Cancellation is a first-class outcome, not an error** (owner's rule): a
/// seller who closed the Apple sheet did not fail at anything, and showing
/// them a red message for it is the app calling them wrong.
class SignInResult {
  const SignInResult.signedIn(this.uid) : wasCancelled = false;

  const SignInResult.cancelled() : uid = null, wasCancelled = true;

  final String? uid;
  final bool wasCancelled;
}

/// Signing in and getting out again.
///
/// **Two ways in, both delegated: Apple and Google** (owner's rule, `CLAUDE.md`
/// hard rule 1). There is no email/password, so this app never sees, stores or
/// resets a password — which is also why there is nothing here to log that
/// could leak one (hard rule 9).
///
/// The only thing that crosses this line is a uid and a provider. No `User`,
/// no `UserCredential`, no `FirebaseAuthException`: `presentation/` is written
/// as if Firebase Auth does not exist, and every failure arrives as an
/// `AppFailure` (hard rule 6).
abstract interface class AuthRepository {
  /// Native Sign in with Apple, then exchange the credential with Firebase.
  Future<SignInResult> signInWithApple();

  /// Native Google Sign-In, then exchange the id token with Firebase.
  Future<SignInResult> signInWithGoogle();

  /// Ends the Firebase session **and** the provider's own, so the next sign-in
  /// asks which account rather than silently reusing the last one — which is
  /// what a seller signing out on a shared phone is trying to prevent.
  Future<void> signOut();

  /// Deletes the account (plan §25).
  ///
  /// Firebase refuses this on an old session with `requires-recent-login`,
  /// which arrives as `AppFailureKind.unauthenticated` — the screen asks the
  /// user to sign in again rather than showing a failure they cannot act on.
  Future<void> deleteAccount();
}
