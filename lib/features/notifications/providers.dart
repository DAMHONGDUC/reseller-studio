/// Riverpod wiring for `notifications`. Other features import this file —
/// never anything under `notifications/data/` or `notifications/presentation/`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/firestore/user_collections.dart';
import '../auth/providers.dart';
import '../workspace/providers.dart';
import 'data/datasources/push_messaging.dart';
import 'data/repositories/firestore_device_repository.dart';
import 'data/repositories/firestore_notification_repository.dart';
import 'domain/entities/app_notification.dart';
import 'domain/repositories/device_repository.dart';
import 'domain/repositories/notification_repository.dart';
import 'presentation/controllers/notification_controller.dart';
import 'presentation/controllers/push_controller.dart';

/// The paths under the signed-in person's own user document, or null when
/// nobody is signed in.
final Provider<UserCollections?> userCollectionsProvider =
    Provider<UserCollections?>((Ref ref) {
      final String? uid = ref.watch(currentUidProvider);

      if (uid == null) return null;

      return UserCollections(ref.watch(firebaseFirestoreProvider), uid);
    });

/// **No mock branch, and that is the same call the audit log made.**
///
/// The inbox has exactly one writer — Cloud Functions — so there is nothing
/// for an in-memory version to stand in for. Mock mode gets the same empty
/// inbox a new account does, and the screen says so rather than inventing
/// notifications nobody was sent.
final Provider<NotificationRepository?> notificationRepositoryProvider =
    Provider<NotificationRepository?>((Ref ref) {
      final UserCollections? collections = ref.watch(userCollectionsProvider);

      if (collections == null) return null;

      return FirestoreNotificationRepository(collections);
    });

final Provider<DeviceRepository?> deviceRepositoryProvider =
    Provider<DeviceRepository?>((Ref ref) {
      final UserCollections? collections = ref.watch(userCollectionsProvider);

      if (collections == null) return null;

      return FirestoreDeviceRepository(collections);
    });

/// The FCM plugin, behind a provider so a test can override it and so nothing
/// else in `lib/` names `FirebaseMessaging`.
final Provider<PushMessaging> pushMessagingProvider = Provider<PushMessaging>(
  (Ref ref) => const PushMessaging(),
);

/// The inbox, newest first.
final StreamProvider<List<AppNotification>> notificationsProvider =
    StreamProvider<List<AppNotification>>((Ref ref) {
      final NotificationRepository? repository = ref.watch(
        notificationRepositoryProvider,
      );

      // Null is signed out — a state the shell renders, so an empty stream
      // rather than a throw. Same reasoning as the audit log's provider.
      if (repository == null) {
        return Stream<List<AppNotification>>.value(const <AppNotification>[]);
      }

      return repository.watchRecent();
    });

/// What the bell wears.
///
/// **Folded from the page the inbox already streams**, not counted with a
/// second query: `where readAt == null` alongside the ordering would need a
/// composite index to answer a number this list already carries.
final Provider<int> unreadNotificationCountProvider = Provider<int>((Ref ref) {
  final List<AppNotification> notifications =
      ref.watch(notificationsProvider).value ?? const <AppNotification>[];

  return notifications.where((AppNotification n) => n.isUnread).length;
});

final NotifierProvider<NotificationController, bool>
notificationControllerProvider =
    NotifierProvider<NotificationController, bool>(NotificationController.new);

/// Device registration and push taps.
///
/// **Watched by `ResellerStudioApp` so it is alive for the whole session.** A
/// controller nothing watches is one Riverpod never builds, and the device
/// would never register.
final NotifierProvider<PushController, void> pushControllerProvider =
    NotifierProvider<PushController, void>(PushController.new);
