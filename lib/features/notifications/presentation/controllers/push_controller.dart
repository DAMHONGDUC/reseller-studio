import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/providers.dart';
import '../../data/datasources/push_messaging.dart';
import '../../domain/repositories/device_repository.dart';
import '../../providers.dart';

/// Registers this device for pushes, and opens what a tapped one points at.
///
/// **It starts when somebody signs in and stops when they sign out**, because
/// a token is registered *to an account*: a device left registered after
/// sign-out is one that would buzz the next person to hold the phone with the
/// last person's orders. [unregister] is called by the sign-out flow while
/// the session is still valid — the rules refuse the delete a moment later.
///
/// **Nothing here decides what a notification says.** The functions write the
/// row and the text; this is the plumbing that makes the device reachable and
/// turns a tap into a route.
class PushController extends Notifier<void> {
  StreamSubscription<String>? _tokenRefreshes;
  StreamSubscription<RemoteMessage>? _opened;

  /// The token this device is currently registered under, so sign-out can
  /// delete exactly that document rather than guessing at one.
  String? _token;

  @override
  void build() {
    final bool ready = ref.watch(firebaseReadyProvider);
    final String? uid = ref.watch(currentUidProvider);

    ref.onDispose(_cancel);

    // No Firebase is a build with no backend at all, and no uid is a guest —
    // both render the whole app, and neither has an account to register a
    // device against.
    if (!ready || uid == null) return;

    unawaited(_start());
  }

  /// Ask, register, then listen. **Not awaited by `build`** — a provider that
  /// blocked on a permission dialog would hold the first frame behind it.
  Future<void> _start() async {
    final PushMessaging messaging = ref.read(pushMessagingProvider);
    final DeviceRepository? devices = ref.read(deviceRepositoryProvider);

    if (devices == null) return;

    try {
      final bool granted = await messaging.requestPermission();

      // Refused is a decision, not a failure: the inbox still fills, because
      // the notification is the Firestore row and the push is a copy of it.
      if (!granted) return;

      _tokenRefreshes = messaging.tokenRefreshes().listen((String token) {
        unawaited(_registerToken(devices, token, messaging.platform));
      });
      _opened = messaging.opened().listen(_open);

      // The tap that started the app from cold arrives here rather than on
      // the stream, and only once.
      final RemoteMessage? initial = await messaging.initialMessage();

      if (initial != null) _open(initial);

      // Last, and deliberately not awaited: on iOS this waits for the APNs
      // token, and a tapped push must not sit behind that. Everything under
      // it logs its own failures.
      unawaited(_registerCurrentToken(messaging, devices));
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notification,
        'Push setup failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerCurrentToken(
    PushMessaging messaging,
    DeviceRepository devices,
  ) async {
    final String? token = await messaging.token();

    // Null on a simulator with no APNs token, which is ordinary rather than
    // broken — see `PushMessaging.token`.
    if (token == null) return;

    await _registerToken(devices, token, messaging.platform);
  }

  Future<void> _registerToken(
    DeviceRepository devices,
    String token,
    String platform,
  ) async {
    try {
      await devices.register(token: token, platform: platform);
      _token = token;
    } catch (error, stackTrace) {
      // Already logged by the repository; caught again so a failed
      // registration leaves the app working rather than taking the tab down.
      SdLogger.error(
        LogTagConstant.notification,
        'Device registration failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Open what a tapped push points at.
  ///
  /// **Only an in-app route is followed.** The payload comes from the server,
  /// and a value that is not one of this app's own paths is refused rather
  /// than handed to the router — a push is the one input to the app that no
  /// screen and no seller composed.
  void _open(RemoteMessage message) {
    final String route = message.data['route']?.toString() ?? '';

    if (!route.startsWith('/')) {
      SdLogger.warning(
        LogTagConstant.notification,
        'Push carried no usable route',
        <String, Object>{'type': message.data['type']?.toString() ?? ''},
      );

      return;
    }

    SdLogger.action(
      LogTagConstant.notification,
      'Push opened',
      <String, Object>{
        'route': route,
        'type': message.data['type']?.toString() ?? '',
      },
    );

    AppAnalytics.instance.pushOpened(
      type: message.data['type']?.toString() ?? '',
    );
    ref.read(routerProvider).go(route);
  }

  /// Called by sign-out, **before** the session ends.
  ///
  /// Two halves, and both matter: the document goes so the account stops
  /// naming this device, and the token itself is deleted so the entry left
  /// behind anywhere else is dead rather than pointed at the next person to
  /// sign in here.
  Future<void> unregister() async {
    final DeviceRepository? devices = ref.read(deviceRepositoryProvider);
    final String? token = _token;

    _cancel();

    if (devices == null || token == null) return;

    try {
      await devices.forget(token);
      await ref.read(pushMessagingProvider).deleteToken();
      _token = null;
    } catch (error, stackTrace) {
      // Never rethrown: a seller signing out must sign out, whatever the
      // token registry thinks.
      SdLogger.error(
        LogTagConstant.notification,
        'Device unregistration failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _cancel() {
    unawaited(_tokenRefreshes?.cancel());
    unawaited(_opened?.cancel());
    _tokenRefreshes = null;
    _opened = null;
  }
}
