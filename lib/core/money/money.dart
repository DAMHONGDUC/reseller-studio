import 'package:intl/intl.dart';

import 'currency_decimals.dart';
import 'currency_input_utils.dart';

/// An amount of money, stored as an integer number of **minor units** — cents
/// for USD, đồng for VND.
///
/// **Never a `double`.** `19.99` is not representable in binary floating
/// point; it is stored as something microscopically close, and a report that
/// sums four hundred rows accumulates the error until a total is visibly a
/// cent out. A reseller reconciling a payout against the app is exactly the
/// user who notices. `CLAUDE.md` hard rule 4.
///
/// **A `Money?` of null means "not known", and that is not the same as
/// [zero].** Hard rule 5: an item whose cost nobody has entered has a null
/// cost and renders `—`; an item that was free has `Money.zero` and renders
/// as a real amount. Collapsing the two is how an app tells a seller they
/// made no profit when the truth is nobody told it what they paid.
///
/// Arithmetic between two different currencies throws rather than guessing.
/// There is no exchange rate in this class on purpose — a rate belongs to a
/// date, and the date belongs to the transaction, not to the arithmetic.
final class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  /// Zero in [currency]. A real amount, not an absent one — see the class doc.
  const Money.zero(this.currency) : minor = 0;

  /// Parse a major-unit amount a human typed: `'19.99'` → `1999` minor units.
  ///
  /// Returns null for anything unparseable **and for the empty string**,
  /// because an empty price field means "not entered", which is precisely the
  /// null case the class doc describes. A form that turned an empty box into
  /// `Money.zero` would be claiming the item is free.
  ///
  /// **The decimal count comes from the currency**, not from a default: a
  /// đồng has no subdivision, so `'450000'` in VND is 450000 minor units and
  /// not 45,000,000. See [CurrencyDecimals].
  static Money? tryParse(String input, String currency) {
    final String trimmed = input.trim().replaceAll(',', '');

    if (trimmed.isEmpty) return null;

    final double? major = double.tryParse(trimmed);

    if (major == null) return null;

    // `round`, not `toInt`: toInt truncates, so 0.1 + 0.2 arriving as
    // 0.30000000000000004 would be fine but 19.99 arriving as 19.989999…
    // would silently become 1998.
    return Money(
      (major * CurrencyDecimals.factorFor(currency)).round(),
      currency,
    );
  }

  /// The amount in minor units. Negative is meaningful: a loss, a refund.
  final int minor;

  /// ISO 4217 code — `USD`, `VND`, `EUR`.
  final String currency;

  /// How many decimal places this currency shows — 2 for USD, 0 for VND.
  int get decimals => CurrencyDecimals.of(currency);

  /// The amount in major units, as a double.
  ///
  /// **For display and export only.** Every calculation stays in [minor]; a
  /// double is exactly the representation hard rule 4 exists to keep out of
  /// the arithmetic.
  double get major => minor / CurrencyDecimals.factorFor(currency);

  /// What goes back into a text field the seller edits: `1,219.99`, or
  /// `450,000` for a currency with no minor unit.
  ///
  /// Round-trips through [tryParse] unchanged, which is the whole contract —
  /// an edit form that reformatted the number it was given would change an
  /// amount nobody touched.
  String toInputString() => CurrencyInputUtils.format(
    major.toStringAsFixed(decimals),
    decimalPlaces: decimals,
  );

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  bool get isPositive => minor > 0;

  Money operator +(Money other) =>
      Money(minor + _checked(other).minor, currency);

  Money operator -(Money other) =>
      Money(minor - _checked(other).minor, currency);

  Money operator -() => Money(-minor, currency);

  /// Scale by a count — three of the same item on one order line.
  Money operator *(int factor) => Money(minor * factor, currency);

  /// Apply a rate, such as a marketplace fee percentage.
  ///
  /// Rounds rather than truncates, so a 12.9% fee on $19.99 comes out at the
  /// nearest cent instead of always in the platform's favour.
  Money applyRate(double rate) => Money((minor * rate).round(), currency);

  /// This as a fraction of [total], or null when [total] is zero.
  ///
  /// Null rather than zero or infinity: "what percentage of nothing" has no
  /// answer, and every caller renders an unanswerable ratio as `—`.
  double? ratioOf(Money total) {
    _checked(total);

    if (total.minor == 0) return null;

    return minor / total.minor;
  }

  /// Format for display: `$19.99`, `₫450.000`.
  ///
  /// [locale] decides the grouping and decimal separators, so a Vietnamese
  /// user sees `450.000` where an American sees `450,000`. Pass the app's
  /// current locale — never let this default silently, or the two locales
  /// disagree about what a thousands separator is.
  String format({String? locale, bool showSymbol = true}) {
    final NumberFormat formatter = showSymbol
        ? NumberFormat.simpleCurrency(locale: locale, name: currency)
        : NumberFormat.decimalPattern(locale);

    // The currency's own decimal count, not the formatter's: `decimalPattern`
    // reports 3 whatever currency it is asked about, and dividing a VND
    // amount by a thousand is how ₫450.000 becomes ₫450.
    return formatter.format(major);
  }

  /// Compact form for a dense tile: `$1.2K`, `$45K`.
  ///
  /// Home's overview tiles and the analytics headline figures use this — a
  /// full `$1,234,567.89` in a quarter-width tile either overflows or shrinks
  /// to unreadable.
  ///
  /// **`compactSimpleCurrency`, not `compactCurrency`.** The latter renders
  /// the ISO code verbatim — `USD439` — because it treats `name` as the
  /// symbol to print. The `simple` variant looks the code up and prints `$439`.
  ///
  /// **And no decimals below a thousand.** The compact formatter shortens
  /// anything with a magnitude — `$1.2K` — but hands back the full `$60.00`
  /// under it, which is two characters more than a quarter-width tile holds:
  /// Home's Stock tile read `$60....`. A tile is a glance, so the pennies go.
  String formatCompact({String? locale}) {
    final NumberFormat formatter = NumberFormat.compactSimpleCurrency(
      locale: locale,
      name: currency,
    );

    if (major.abs() < 1000) formatter.maximumFractionDigits = 0;

    return formatter.format(major);
  }

  Money _checked(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine $currency with ${other.currency}. Convert first — '
        'a rate belongs to a transaction date, not to this operator.',
      );
    }

    return other;
  }

  @override
  int compareTo(Money other) => minor.compareTo(_checked(other).minor);

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => 'Money($minor $currency)';
}

/// Sum helpers that keep the "null means unknown" distinction intact.
extension MoneyIterableX on Iterable<Money> {
  /// Total, or null when empty.
  ///
  /// Null rather than zero for an empty list, so a caller can tell "no rows"
  /// from "rows that sum to nothing" — the same distinction the class doc
  /// draws, applied to aggregates.
  Money? totalOrNull() {
    if (isEmpty) return null;

    return reduce((Money a, Money b) => a + b);
  }
}

/// Sum of the amounts that are known, ignoring the unknown ones.
extension MoneyNullableIterableX on Iterable<Money?> {
  /// Total of the non-null amounts, or null when none are known.
  ///
  /// **This deliberately does not treat a null as zero.** Ten items where two
  /// have costs gives the total of those two — the alternative claims the
  /// other eight were free, and every profit figure built on it would be
  /// overstated.
  Money? totalOfKnown() {
    final Iterable<Money> known = whereType<Money>();

    return known.isEmpty ? null : known.reduce((Money a, Money b) => a + b);
  }

  /// True when every amount is known. Analytics uses this to mark a figure as
  /// partial rather than presenting it as complete.
  bool get allKnown => !any((Money? amount) => amount == null);
}
