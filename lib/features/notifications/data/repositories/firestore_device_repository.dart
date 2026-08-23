import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/user_collections.dart';
import '../../domain/repositories/device_repository.dart';

/// The FCM tokens this person's devices are reachable at.
///
/// **The token is the document id.** That is what makes registration
/// idempotent — the same phone re-registering on every launch rewrites one
/// document rather than growing a collection — and it is what lets the send
/// path delete exactly the entry the platform reported dead.
///
/// **Nothing here logs the token** (hard rule 9). A token is a way to push
/// arbitrary text onto somebody's phone; the log line carries the platform
/// and nothing else.
class FirestoreDeviceRepository implements DeviceRepository {
  const FirestoreDeviceRepository(this._collections);

  final UserCollections _collections;

  @override
  Future<void> register({required String token, required String platform}) =>
      FailureMapper.guard('register device', () async {
        await _collections.devices.doc(token).set(<String, Object?>{
          'token': token,
          'platform': platform,
          'updatedAt': FirestoreMapper.serverTimestamp,
        });

        SdLogger.info(
          LogTagConstant.notification,
          'Device registered',
          <String, Object>{'platform': platform},
        );
      });

  @override
  Future<void> forget(String token) =>
      FailureMapper.guard('forget device', () async {
        await _collections.devices.doc(token).delete();

        SdLogger.info(LogTagConstant.notification, 'Device forgotten');
      });
}
