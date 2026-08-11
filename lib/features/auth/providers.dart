/// Riverpod wiring for `auth`. Other features import this file — never
/// anything under `auth/data/` or `auth/presentation/`.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The `FirebaseAuth` instance, behind a provider so a test can override it.
final Provider<FirebaseAuth> firebaseAuthProvider = Provider<FirebaseAuth>(
  (Ref ref) => FirebaseAuth.instance,
);

/// Who is signed in, as a stream.
///
/// **`authStateChanges` is the wrong stream for this app and `userChanges` is
/// the right one.** The first fires only on sign-in and sign-out; the second
/// also fires when the profile changes — a display name edit, an email
/// verification landing, a provider being linked. Seller OS shows the account
/// on Home and in Settings, and with `authStateChanges` those screens keep
/// rendering the pre-edit user until the app is restarted.
final StreamProvider<User?> authUserProvider = StreamProvider<User?>(
  (Ref ref) => ref.watch(firebaseAuthProvider).userChanges(),
);

/// Whether anyone is signed in at all. What the router redirects on.
///
/// Null while the first auth check is still in flight — the router must show
/// the splash screen rather than the login screen for that moment, or a
/// returning user sees a login form flash before their own data.
final Provider<bool?> isSignedInProvider = Provider<bool?>((Ref ref) {
  final AsyncValue<User?> user = ref.watch(authUserProvider);

  return user.when(
    data: (User? value) => value != null,
    // A failure to *read* auth state is not a signed-in state. Treating it as
    // signed-out sends the user to a login screen they can retry from, which
    // is the only recoverable branch.
    error: (Object error, StackTrace stackTrace) => false,
    loading: () => null,
  );
});
