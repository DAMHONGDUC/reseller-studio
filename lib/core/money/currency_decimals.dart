/// How many minor units make up one major unit of a currency.
///
/// **Not every currency has cents.** `Money` stores minor units, so the
/// conversion between what a seller types (`450000`) and what is stored is a
/// per-currency question: 100 for USD, and **1 for VND** — a đồng has no
/// subdivision. Assuming 100 everywhere makes every VND figure in the app
/// wrong by a factor of a hundred, which is the kind of error a seller
/// notices immediately and never trusts the app about again.
///
/// The list is the zero-decimal currencies from ISO 4217 that this product
/// plausibly meets. Anything unknown gets 2, which is right for the
/// overwhelming majority and is the safe default: it under-reports a
/// zero-decimal currency rather than inflating it.
final class CurrencyDecimals {
  /// What a currency uses when it is not in [_zeroDecimal].
  static const int fallback = 2;

  /// ISO 4217 codes with no minor unit at all.
  ///
  /// Three-decimal currencies (KWD, BHD, OMR) are deliberately absent: none
  /// of them is in the workspace picker, and guessing at one is worse than
  /// the 2 they would fall back to. Add them with a test when they are needed.
  static const Set<String> _zeroDecimal = <String>{
    'VND',
    'JPY',
    'KRW',
    'IDR',
    'CLP',
    'ISK',
    'PYG',
    'RWF',
    'UGX',
    'VUV',
    'XAF',
    'XOF',
    'XPF',
  };

  static int of(String currency) =>
      _zeroDecimal.contains(currency.toUpperCase()) ? 0 : fallback;

  /// Ten to the power of the currency's decimal count — 100 for USD, 1 for
  /// VND. The multiplier between major and minor units.
  static int factorFor(String currency) {
    int result = 1;

    for (int i = 0; i < of(currency); i++) {
      result *= 10;
    }

    return result;
  }
}
