/// Where this person's pushes are delivered.
///
/// **A device, not a user setting.** One seller signs in on a phone and a
/// tablet and expects both to buzz, so the token is a document per device
/// rather than a field on the profile.
abstract interface class DeviceRepository {
  /// Remember an FCM token. Idempotent — re-registering the same token on the
  /// same device rewrites one document rather than making a second.
  Future<void> register({required String token, required String platform});

  /// Forget one, at sign-out.
  ///
  /// **Before the session ends, never after.** `users/{uid}/devices` is
  /// writable only by that uid, so a delete attempted once the session is
  /// gone is refused — and the token would stay registered to an account that
  /// is no longer the one holding the phone.
  Future<void> forget(String token);
}
