/// How many minor units make up one major unit of a currency.
///
/// **Not every currency has cents.** `Money` stores minor units, so the
/// conversion between what a seller types (`450000`) and what is stored is a
/// per-currency question: 100 for USD, **1 for VND** — a đồng has no
/// subdivision — and **1000 for KWD**. Assuming 100 everywhere makes every VND
/// figure in the app wrong by a factor of a hundred, which is the kind of
/// error a seller notices immediately and never trusts the app about again.
///
/// **Both exception lists are complete, because the picker is.** They used to
/// cover only the currencies a nine-entry list could reach, and the
/// three-decimal group was left out entirely on the grounds that none of them
/// was selectable. `CurrencyConstant` now offers every ISO 4217 currency, so
/// that reasoning expired with it — a dinar business would have had every
/// amount out by a factor of ten.
///
/// Anything unknown gets 2, which is right for the overwhelming majority and
/// is the safe default: it under-reports a zero-decimal currency rather than
/// inflating it.
final class CurrencyDecimals {
  /// What a currency uses when it is in neither list below.
  static const int fallback = 2;

  /// ISO 4217 codes with no minor unit at all.
  ///
  /// **`IDR` is a deliberate deviation.** ISO gives the rupiah an exponent of
  /// 2, but the sen has not circulated in decades and no Indonesian price is
  /// ever quoted in it. It was already treated as zero-decimal here; changing
  /// it now would silently multiply every stored rupiah amount by a hundred.
  static const Set<String> _zeroDecimal = <String>{
    'BIF',
    'CLP',
    'DJF',
    'GNF',
    'IDR',
    'ISK',
    'JPY',
    'KMF',
    'KRW',
    'PYG',
    'RWF',
    'UGX',
    'VND',
    'VUV',
    'XAF',
    'XOF',
    'XPF',
  };

  /// ISO 4217 codes with a thousand minor units to the major one — the Gulf
  /// and North African dinars, plus the Omani rial.
  static const Set<String> _threeDecimal = <String>{
    'BHD',
    'IQD',
    'JOD',
    'KWD',
    'LYD',
    'OMR',
    'TND',
  };

  static int of(String currency) {
    final String code = currency.toUpperCase();

    if (_zeroDecimal.contains(code)) return 0;
    if (_threeDecimal.contains(code)) return 3;

    return fallback;
  }

  /// Ten to the power of the currency's decimal count — 100 for USD, 1 for
  /// VND, 1000 for KWD. The multiplier between major and minor units.
  static int factorFor(String currency) {
    int result = 1;

    for (int i = 0; i < of(currency); i++) {
      result *= 10;
    }

    return result;
  }
}
