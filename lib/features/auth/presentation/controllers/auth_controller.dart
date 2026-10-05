import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../notifications/providers.dart';
import '../../../workspace/domain/repositories/workspace_repository.dart';
import '../../../workspace/providers.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../providers.dart';

/// The two ways a session ends, both started from Settings.
///
/// Named rather than a bool because they run from the same card and take
/// visibly different amounts of time — the delete walks every subcollection
/// server-side — so the seller must be able to see *which* one is running.
enum AccountAction { signOut, deleteAccount }

/// What the auth controller is doing right now.
///
/// [busyProvider] rather than a plain bool, so only the button that was tapped
/// shows a spinner — two buttons both spinning would suggest two sign-ins are
/// in flight. [busyAction] is the same idea for the Settings card.
class AuthFormState {
  const AuthFormState({this.busyProvider, this.busyAction});

  final AuthProviderKind? busyProvider;
  final AccountAction? busyAction;

  bool get isBusy => busyProvider != null || busyAction != null;

  bool isBusyWith(AuthProviderKind provider) => busyProvider == provider;

  bool isRunning(AccountAction action) => busyAction == action;
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
  ///
  /// **It returns the moment the session exists.** The profile write and the
  /// billing identity run after, unawaited: each is a network round trip with
  /// no upper bound, and awaiting them kept the button spinning on a valid
  /// sign-in — App Review's "loaded indefinitely". Both log their own failure.
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
      unawaited(_ensureProfile(uid));
      unawaited(_identifyForBilling(uid));

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

  /// **The device is unregistered before the session ends, not after.**
  /// `users/{uid}/devices` is writable only by that uid, so a delete
  /// attempted a moment later is refused — and a token left registered is one
  /// that would buzz the next person to hold this phone with the last
  /// person's orders.
  Future<void> signOut() async {
    state = const AuthFormState(busyAction: AccountAction.signOut);

    // Neither cleanup step is allowed to fail the sign-out — a seller who
    // tapped it must end up signed out whatever a plugin does.
    await _unregisterDevice();
    await _forgetBillingIdentity();

    try {
      await ref.read(authRepositoryProvider).signOut();
      SdCrashReporter.instance.setUserId(null);
      AppAnalytics.instance.signedOut();

      // **After the session ends, never before.** The wipe is what makes the
      // app blank rather than showing the next person the last one's stock
      // (`docs/rules/GUEST_MODE.md`), and running it first would empty a
      // device that then failed to sign out.
      await ref.read(guestResetServiceProvider).run();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.logout,
        'Sign out failed',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      _clearBusy();
    }
  }

  /// **The slowest thing in the app, and the one that must look busy.** The
  /// function walks every subcollection the account owns and may raise the
  /// provider sheet on the way, so a card that sat there unchanged was one a
  /// seller tapped again.
  Future<void> deleteAccount() async {
    state = const AuthFormState(busyAction: AccountAction.deleteAccount);

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
    } finally {
      _clearBusy();
    }
  }

  /// Both actions end the session, and the router tears the stack down the
  /// moment it does — so this can land after the provider is gone.
  void _clearBusy() {
    if (!ref.mounted) return;

    state = const AuthFormState();
  }

  /// Drop this device's push token, and never fail the sign-out over it.
  ///
  /// It has to happen before the session ends — `users/{uid}/devices` is
  /// writable only by that uid — but a token that outlives the session is a
  /// smaller harm than a seller who cannot get out of the app.
  Future<void> _unregisterDevice() async {
    try {
      await ref.read(pushControllerProvider.notifier).unregister();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.logout,
        'Device not unregistered — its token stays until it expires',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear the billing identity, and never fail the sign-out over it.
  ///
  /// This is the one that was actually stopping people: RevenueCat throws on
  /// a log-out it never logged in for, which is the state after any launch
  /// where `identify` did not run — and that threw away the sign-out with it.
  Future<void> _forgetBillingIdentity() async {
    try {
      await ref.read(subscriptionRepositoryProvider).forget();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.logout,
        'Billing identity not cleared — the next sign-in overwrites it',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Tell the billing provider which account this is.
  ///
  /// **Not allowed to fail the sign-in either**, for the same reason as the
  /// profile write: the session is valid, and a seller blocked at the login
  /// screen because a billing SDK was unreachable is the wrong trade. The
  /// cost of it failing is that the webhook cannot connect a payment to this
  /// account until the next sign-in, which the log names.
  Future<void> _identifyForBilling(String uid) async {
    try {
      await ref.read(subscriptionRepositoryProvider).identify(uid);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.subscription,
        'Billing identity not set — entitlement will not reach the backend',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'uid': uid},
      );
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
