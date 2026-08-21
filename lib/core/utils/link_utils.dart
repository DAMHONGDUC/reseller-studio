import 'package:system_design/common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/log_tag_constant.dart';

/// Opening something outside the app — a policy page, a support address.
///
/// **It answers rather than throws.** Every caller is a tap on a row, and
/// there is nothing a seller can do about a browser that refused to open, so
/// the caller shows a message and the log keeps what actually happened
/// (hard rule 8). `launchUrl` both returns `false` and throws depending on the
/// platform and the failure, which is why one place wraps it.
final class LinkUtils {
  const LinkUtils._();

  /// Hands [url] to the OS. Returns whether anything opened.
  ///
  /// An empty or unparseable [url] is a configuration mistake, not a runtime
  /// one — it is logged and refused rather than launched, because a missing
  /// env key reaches here as `''`.
  static Future<bool> open(String url) async {
    final Uri? uri = url.isEmpty ? null : Uri.tryParse(url);

    if (uri == null || !uri.hasScheme) {
      SdLogger.error(
        LogTagConstant.link,
        'Refused to open a link with no scheme',
        data: <String, Object>{'length': url.length},
      );

      return false;
    }

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (opened) {
        SdLogger.action(LogTagConstant.link, 'Opened link', <String, Object>{
          'host': uri.host,
        });
      } else {
        SdLogger.error(
          LogTagConstant.link,
          'Nothing handled the link',
          data: <String, Object>{'host': uri.host},
        );
      }

      return opened;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.link,
        'Opening a link threw',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'host': uri.host},
      );

      return false;
    }
  }
}
