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

        SdLogger.action(
          LogTagConstant.deleteAccount,
          'Delete account',
          <String, Object>{'uid': uid},
        );

        final HttpsCallableResult<Object?> result = await _functions
            .httpsCallable(CallableConstant.deleteAccount)
            .call<Object?>();

        await _auth.signOut();

        SdLogger.action(
          LogTagConstant.deleteAccount,
          'Account deleted',
          <String, Object?>{'uid': uid, 'result': result.data},
        );
      });

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
