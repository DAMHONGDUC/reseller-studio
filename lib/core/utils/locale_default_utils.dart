import 'dart:io';

/// What country and currency a business starts on when nobody has said.
///
/// **The launch markets are the only two answers** (`CLAUDE.md`): `us` and
/// `uk`. A guest's business is created without asking — hard rule 2 — so it
/// has to guess, and a guess between two markets is right far more often than
/// a map of 249 countries would be maintained. The seller changes it in
/// Settings, and that is the correction path.
final class LocaleDefaultUtils {
  static const String _uk = 'uk';
  static const String _us = 'us';
  static const String _gbp = 'GBP';
  static const String _usd = 'USD';

  /// The region subtag of the platform locale, upper-cased, or empty.
  ///
  /// `Platform.localeName` is `en_GB` on Android and `en_GB` or `en-GB` on
  /// iOS depending on the locale, so both separators are cut.
  static String regionOf(String localeName) {
    final String head = localeName.split('.').first;
    final int cut = head.lastIndexOf(RegExp(r'[_-]'));

    if (cut < 0) return '';

    return head.substring(cut + 1).toUpperCase();
  }

  static String countryFor(String localeName) =>
      regionOf(localeName) == 'GB' ? _uk : _us;

  static String currencyFor(String localeName) =>
      regionOf(localeName) == 'GB' ? _gbp : _usd;

  /// The device's locale, read once at the point a business is created.
  static String get deviceLocale => Platform.localeName;
}
