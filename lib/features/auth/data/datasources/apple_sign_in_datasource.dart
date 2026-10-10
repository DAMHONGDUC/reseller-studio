import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the native Sign in with Apple sheet hands back.
///
/// The name arrives on the first sign-in only — Apple never sends it again.
class AppleIdCredential {
  const AppleIdCredential({
    required this.idToken,
    required this.rawNonce,
    this.givenName,
    this.familyName,
  });

  final String idToken;
  final String rawNonce;
  final String? givenName;
  final String? familyName;
}

/// The Dart half of `ios/Runner/AppleSignInPlugin.swift`.
///
/// iOS only: the app presents Apple's sheet itself there, because FlutterFire's
/// own path can present from no window and never answer (App Review, iPad).
/// Every other platform keeps Firebase's provider flow.
///
/// Nothing here logs the token (hard rule 9); a failure is logged by the
/// repository's `FailureMapper.guard`, which this rethrows into.
class AppleSignInDatasource {
  const AppleSignInDatasource();

  static const MethodChannel _channel = MethodChannel(
    'app.dd.reseller.studio/apple_sign_in',
  );

  static const String _cancelledCode = 'canceled';

  /// True where [requestCredential] is the way Apple sign-in runs.
  static bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Null when the seller closed the sheet — a cancellation, not a failure.
  Future<AppleIdCredential?> requestCredential() async {
    final Map<String, Object?>? raw;

    try {
      raw = await _channel.invokeMapMethod<String, Object?>(
        'requestCredential',
      );
    } on PlatformException catch (error) {
      if (error.code == _cancelledCode) return null;

      rethrow;
    }

    final Object? idToken = raw?['idToken'];
    final Object? rawNonce = raw?['rawNonce'];

    if (idToken is! String || rawNonce is! String) {
      throw PlatformException(
        code: 'invalid-credential',
        message: 'Apple sign-in answered without a token',
      );
    }

    return AppleIdCredential(
      idToken: idToken,
      rawNonce: rawNonce,
      givenName: raw?['givenName'] as String?,
      familyName: raw?['familyName'] as String?,
    );
  }
}
