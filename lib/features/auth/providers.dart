/// Riverpod wiring for `auth`. Other features import this file — never
/// anything under `auth/data/` or `auth/presentation/`.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/repositories/firebase_auth_repository.dart';
import 'domain/repositories/auth_repository.dart';

/// Whether Firebase came up at all.
///
/// **Nothing may touch `FirebaseAuth.instance` without checking this first.**
/// It throws `[core/no-app]` when `Firebase.initializeApp` has not run, and
/// `AppBootstrap` deliberately skips that when the build carries no Firebase
/// config — so on a machine with no `firebase_options.dart` the very first
/// read of auth state would take the app down before its first frame.
///
/// Not configured is treated as **signed out**, which is a state the app now
/// renders properly: the five tabs come up empty and sign-in fails with the
/// one message hard rule 6 allows. That is what the dev auth bypass used to
/// be for, and why there no longer is one.
final Provider<bool> firebaseReadyProvider = Provider<bool>(
  (Ref ref) => Firebase.apps.isNotEmpty,
);

/// The `FirebaseAuth` instance, behind a provider so a test can override it.
final Provider<FirebaseAuth> firebaseAuthProvider = Provider<FirebaseAuth>(
  (Ref ref) => FirebaseAuth.instance,
);

/// Sign in, sign up, reset, sign out, delete — behind the domain interface,
/// so nothing in `presentation/` names a Firebase type.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (Ref ref) => FirebaseAuthRepository(ref.watch(firebaseAuthProvider)),
    );

/// Who is signed in, as a stream.
///
/// **`authStateChanges` is the wrong stream for this app and `userChanges` is
/// the right one.** The first fires only on sign-in and sign-out; the second
/// also fires when the profile changes — a display name edit, an email
/// verification landing, a provider being linked. Seller OS shows the account
/// on Home and in Settings, and with `authStateChanges` those screens keep
/// rendering the pre-edit user until the app is restarted.
final StreamProvider<User?> authUserProvider = StreamProvider<User?>((Ref ref) {
  // Checked before `firebaseAuthProvider` is watched, never after: watching it
  // is itself what throws when there is no Firebase app.
  if (!ref.watch(firebaseReadyProvider)) return Stream<User?>.value(null);

  return ref.watch(firebaseAuthProvider).userChanges();
});

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

/// The signed-in user's uid, or null when nobody is.
///
/// **Every Firestore path and `createdBy` field reads this, never
/// `FirebaseAuth.instance.currentUser!.uid`.** Reaching for `currentUser`
/// directly crashes on a build with no Firebase app; this provider answers
/// null there, which every caller already handles as "nobody is signed in".
final Provider<String?> currentUidProvider = Provider<String?>((Ref ref) {
  // `.value` is nullable on Riverpod 3's AsyncValue (it was `valueOrNull` in
  // 2.x) and is null while loading or errored — which is the right answer
  // here: nobody is signed in until the stream says so.
  return ref.watch(authUserProvider).value?.uid;
});

