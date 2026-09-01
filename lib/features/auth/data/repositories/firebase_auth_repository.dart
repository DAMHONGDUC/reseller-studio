import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/callable_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../domain/repositories/auth_repository.dart';

/// Apple and Google sign-in, behind the domain interface.
///
/// **The two providers take different routes on purpose.**
///
/// - **Apple** goes through `FirebaseAuth.signInWithProvider`, which uses the
///   native sheet on iOS and a web flow elsewhere, and generates and verifies
///   its own nonce. Doing it by hand would mean a raw nonce, a SHA-256 of it,
///   and a third-party package — three more things to get wrong for an
///   identical result.
/// - **Google** goes through `google_sign_in`, because Firebase's provider
///   flow would open a web view and Google rejects sign-in from embedded web
///   views on Android. The plugin uses the platform account picker.
///
/// Nothing here logs an email, a token or a display name (hard rule 9). The
/// uid is enough to find a session, and it is not a credential.
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._auth, this._functions);

  final FirebaseAuth _auth;

  /// Only [deleteAccount] uses it, and that is the point: the delete is the
  /// one thing here a client is not allowed to do for itself.
  final FirebaseFunctions _functions;

  /// What the function answers on a sign-in it considers too old. It picks
  /// `unauthenticated` over `permission-denied` on purpose — see
  /// `functions/src/lib/caller.ts`.
  static const String _staleSessionCode = 'unauthenticated';

  @override
  Future<SignInResult> signInWithApple() =>
      FailureMapper.guard('sign in with Apple', () async {
        final AppleAuthProvider provider = AppleAuthProvider()
          // Asked for once, and only on the first sign-in — Apple never sends
          // the name again, which is why the profile write happens
          // immediately after rather than "later".
          ..addScope('email')
          ..addScope('name');

        try {
          final UserCredential credential = await _auth.signInWithProvider(
            provider,
          );

          return _signedIn(credential, AuthProviderKind.apple);
        } on FirebaseAuthException catch (error) {
          if (_isCancellation(error.code)) {
            return _cancelled(AuthProviderKind.apple);
          }

          rethrow;
        }
      });

  @override
  Future<SignInResult> signInWithGoogle() =>
      FailureMapper.guard('sign in with Google', () async {
        try {
          final GoogleSignInAccount account = await GoogleSignIn.instance
              .authenticate();

          final String? idToken = account.authentication.idToken;

          if (idToken == null) {
            // A successful authenticate with no id token is a broken plugin
            // contract, not something the seller did — so it becomes a mapped
            // failure rather than a null-check crash in a widget.
            throw const AppFailure(
              AppFailureKind.unknown,
              technicalMessage: 'Google returned no id token',
            );
          }

          final UserCredential credential = await _auth.signInWithCredential(
            GoogleAuthProvider.credential(idToken: idToken),
          );

          return _signedIn(credential, AuthProviderKind.google);
        } on GoogleSignInException catch (error) {
          if (error.code == GoogleSignInExceptionCode.canceled) {
            return _cancelled(AuthProviderKind.google);
          }

          rethrow;
        }
      });

  @override
  Future<void> signOut() => FailureMapper.guard('sign out', () async {
    // Google first, and its failure does not stop the Firebase sign-out: a
    // seller who tapped "sign out" must end up signed out of *this* app
    // whatever the plugin does.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.logout,
        'Google sign-out failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _auth.signOut();

    SdLogger.action(LogTagConstant.logout, 'Signed out');
  });

  /// **The function deletes the login too**, so nothing here calls
  /// `user.delete()`. Doing both would race: the second call arrives with a
  /// uid that no longer exists and fails on a delete that actually worked.
  ///
  /// **A stale sign-in is re-authenticated rather than reported.** The
  /// function reads `auth_time` and refuses anything older than a few
  /// minutes, which is nearly every session — so the provider sheet is
  /// raised and the call is made once more.
  ///
  /// The local sign-out afterwards is not decoration. Deleting the user
  /// server-side does not invalidate the token this device is holding, and
  /// `userChanges` has no event to fire — without it the app sits on a
  /// signed-in shell for an account that is gone.
  @override
  Future<void> deleteAccount() =>
      FailureMapper.guard('delete account', () async {
        final User? user = _auth.currentUser;

        if (user == null) {
          throw const AppFailure(AppFailureKind.unauthenticated);
        }

        final String uid = user.uid;
        Object? deleted;

        SdLogger.action(
          LogTagConstant.deleteAccount,
          'Delete account',
          <String, Object>{'uid': uid},
        );

        try {
          deleted = await _callDelete();
        } on FirebaseFunctionsException catch (error) {
          if (error.code != _staleSessionCode) rethrow;

          if (!await _reauthenticate(user)) return;

          deleted = await _callDelete();
        }

        await _auth.signOut();

        SdLogger.action(
          LogTagConstant.deleteAccount,
          'Account deleted',
          <String, Object?>{'uid': uid, 'result': deleted},
        );
      });

  Future<Object?> _callDelete() async {
    final HttpsCallableResult<Object?> result = await _functions
        .httpsCallable(CallableConstant.deleteAccount)
        .call<Object?>();

    return result.data;
  }

  /// Ask the provider to confirm the seller is still holding the phone.
  ///
  /// **The function refuses a sign-in older than a few minutes**, and almost
  /// every session is: without this the only way to delete an account was to
  /// sign out, sign back in, and get to Settings inside the window. The sheet
  /// that appears is the same one they signed in with.
  ///
  /// Returns false when they close it — a cancellation is not a failure
  /// (owner's rule), so the account simply stays.
  Future<bool> _reauthenticate(User user) async {
    final AuthProviderKind? provider = _providerOf(user);

    if (provider == null) {
      // Nothing this app offers signed this session in, so there is no sheet
      // to raise — the seller signs in again instead.
      throw const AppFailure(
        AppFailureKind.unauthenticated,
        technicalMessage: 'No Apple or Google provider on the current user',
      );
    }

    try {
      switch (provider) {
        case AuthProviderKind.apple:
          await user.reauthenticateWithProvider(AppleAuthProvider());
        case AuthProviderKind.google:
          await _reauthenticateWithGoogle(user);
      }
    } on FirebaseAuthException catch (error) {
      if (_isCancellation(error.code)) return _reauthCancelled(provider);

      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return _reauthCancelled(provider);
      }

      rethrow;
    }

    // The callable is authorized by the token this device holds, so it is
    // refreshed here rather than left carrying the old `auth_time`.
    await user.getIdToken(true);

    SdLogger.info(
      LogTagConstant.deleteAccount,
      'Re-authenticated before delete',
      <String, String>{'provider': provider.name},
    );

    return true;
  }

  Future<void> _reauthenticateWithGoogle(User user) async {
    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate();

    final String? idToken = account.authentication.idToken;

    if (idToken == null) {
      throw const AppFailure(
        AppFailureKind.unknown,
        technicalMessage: 'Google returned no id token',
      );
    }

    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  static bool _reauthCancelled(AuthProviderKind provider) {
    SdLogger.info(
      LogTagConstant.deleteAccount,
      'Re-authentication cancelled — account kept',
      <String, String>{'provider': provider.name},
    );

    return false;
  }

  /// Which of the two providers signed this session in, if either.
  static AuthProviderKind? _providerOf(User user) {
    final Set<String> ids = user.providerData
        .map((UserInfo info) => info.providerId)
        .toSet();

    for (final AuthProviderKind provider in AuthProviderKind.values) {
      if (ids.contains(provider.firebaseProviderId)) return provider;
    }

    return null;
  }

  /// Firebase types the user on a credential as nullable even on success.
  static SignInResult _signedIn(
    UserCredential credential,
    AuthProviderKind provider,
  ) {
    final String? uid = credential.user?.uid;

    if (uid == null) {
      throw const AppFailure(
        AppFailureKind.unknown,
        technicalMessage: 'Auth returned a credential with no user',
      );
    }

    SdLogger.action(LogTagConstant.login, 'Signed in', <String, Object>{
      'uid': uid,
      'provider': provider.name,
      'isNewAccount': credential.additionalUserInfo?.isNewUser ?? false,
    });

    return SignInResult.signedIn(uid);
  }

  /// A cancelled sign-in is logged as what it is — the seller closing a sheet
  /// — and never as an error (owner's rule).
  static SignInResult _cancelled(AuthProviderKind provider) {
    SdLogger.info(LogTagConstant.login, 'Sign-in cancelled', <String, Object>{
      'provider': provider.name,
    });

    return const SignInResult.cancelled();
  }

  /// The codes Firebase uses when the user backs out of a provider flow.
  ///
  /// Three of them because the platforms disagree: iOS reports a cancelled
  /// native sheet, Android a closed custom tab, and the web flow a closed
  /// popup.
  static bool _isCancellation(String code) =>
      code == 'canceled' ||
      code == 'web-context-canceled' ||
      code == 'popup-closed-by-user';
}
