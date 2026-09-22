import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import 'local_database.dart';

/// Taking the device back to a blank guest after a sign-out.
///
/// **Signing out leaves the app blank** — owner's rule, and deliberately the
/// opposite of the sibling app, whose sign-out keeps every local row. A
/// reseller's records belong to a business and a team rather than to a
/// person's own phone, so a device handed to somebody else must not still
/// hold them (`docs/rules/GUEST_MODE.md`).
///
/// Nothing here is allowed to fail the sign-out. A seller who tapped it must
/// end up signed out whatever a store does, which is the same rule the
/// device-unregister and billing steps in `AuthController` follow.
class GuestResetService {
  const GuestResetService(this._db, this._firestore);

  final LocalDatabase _db;
  final FirebaseFirestore _firestore;

  /// Empty the device of the account that just left.
  ///
  /// The Drift wipe is normally a no-op — the drain empties those tables at
  /// sign-in — but a drain interrupted half way leaves rows behind, and those
  /// belong to the seller who is walking away.
  Future<void> run() async {
    await _wipeLocal();
    await _clearFirestoreCache();

    SdLogger.action(LogTagConstant.logout, 'Device returned to guest');
  }

  Future<void> _wipeLocal() async {
    try {
      await _db.wipe();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.logout,
        'Local store wipe failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// **Best effort, and the failure is expected rather than exceptional.**
  /// `clearPersistence` throws `failed-precondition` while any listener is
  /// open, and sign-out happens with the app on screen — the guest shell has
  /// already swapped every repository over, but Firestore's own streams are
  /// torn down on Riverpod's schedule, not on this one.
  ///
  /// What is left behind when it does throw is a disk cache nothing can read
  /// past: every query in the app carries a `workspaceId` filter (hard rule
  /// 14), and the next account does not match the last one's. The cold start
  /// after this clears it for real.
  Future<void> _clearFirestoreCache() async {
    try {
      await _firestore.terminate();
      await _firestore.clearPersistence();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.logout,
        'Firestore cache still open — cleared on next launch instead',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
