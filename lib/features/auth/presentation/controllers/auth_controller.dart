import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../workspace/domain/repositories/workspace_repository.dart';
import '../../../workspace/providers.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../providers.dart';

/// What the login screen is doing right now.
///
/// [busyProvider] rather than a plain bool, so only the button that was tapped
/// shows a spinner — two buttons both spinning would suggest two sign-ins are
/// in flight.
class AuthFormState {
  const AuthFormState({this.busyProvider});

  final AuthProviderKind? busyProvider;

  bool get isBusy => busyProvider != null;

  bool isBusyWith(AuthProviderKind provider) => busyProvider == provider;
}

/// Sign in with Apple or Google, sign out, delete.
///
/// **Two providers, no passwords** (owner's rule). A successful sign-in also
/// ensures the user's profile document exists — done here rather than only on
/// first sign-in, so an account created before that document existed, or one
/// whose write failed, still gets one and can reach workspace setup.
///
/// Each method logs what it attempted, then rethrows: the log is an extra
/// pair of eyes, never a replacement for the screen's error handling. A
/// cancellation is not a failure and is not rethrown.
class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  /// Returns true when a session now exists, false when the seller backed out.
  Future<bool> signIn(AuthProviderKind provider) async {
    final AuthRepository auth = ref.read(authRepositoryProvider);

    state = AuthFormState(busyProvider: provider);

    try {
      final SignInResult result = switch (provider) {
        AuthProviderKind.apple => await auth.signInWithApple(),
        AuthProviderKind.google => await auth.signInWithGoogle(),
      };

      final String? uid = result.uid;

      if (uid == null) return false;

      SdCrashReporter.instance.setUserId(uid);
      AppAnalytics.instance.signedIn(provider: provider.name);
      await _ensureProfile(uid);

      return true;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.login,
        'Sign in failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'provider': provider.name},
      );

      rethrow;
    } finally {
      state = const AuthFormState();
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      SdCrashReporter.instance.setUserId(null);
      AppAnalytics.instance.signedOut();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.logout,
        'Sign out failed',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      SdCrashReporter.instance.setUserId(null);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.deleteAccount,
        'Account deletion failed',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// The profile write is not allowed to fail the sign-in.
  ///
  /// The session is already valid at this point, and blocking a seller at the
  /// login screen over a document they never see would be the wrong trade —
  /// the next sign-in retries it, and `workspaceStatusProvider` sends them to
  /// onboarding meanwhile.
  ///
  /// The name and avatar come from whichever provider they used; Apple sends
  /// the name **only on the very first sign-in**, which is why this runs
  /// immediately rather than at some later convenient moment.
  Future<void> _ensureProfile(String uid) async {
    final WorkspaceRepository workspaces = ref.read(
      workspaceRepositoryProvider,
    );

    try {
      await workspaces.ensureProfile(
        uid: uid,
        displayName: ref.read(authUserProvider).value?.displayName,
        email: ref.read(authUserProvider).value?.email,
        photoUrl: ref.read(authUserProvider).value?.photoURL,
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.login,
        'Could not write user profile after sign in',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'uid': uid},
      );
    }
  }
}

final NotifierProvider<AuthController, AuthFormState> authControllerProvider =
    NotifierProvider<AuthController, AuthFormState>(AuthController.new);
