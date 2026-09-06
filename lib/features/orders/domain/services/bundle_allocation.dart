import '../../../../core/money/money.dart';

/// How a bundle's one price becomes a price per item.
///
/// **A bundle is one payment for several things, and the app has to store it
/// as several lines.** Poshmark bundles and Depop's "2 for £15" are everyday,
/// and before this a seller had to invent per-item prices and write several
/// orders — which destroys the per-item ROI that Sourcing exists to measure.
///
/// **The split is a judgement, not a fact, and the screen says so.** The buyer
/// paid one number; nothing in the world says which part of it was the jacket.
/// Two rules, in order:
///
/// 1. **By expected price**, when every item has one. A £45 jacket and a £15
///    shirt sold together for £48 split 36/12, which is the proportion the
///    seller themselves put on them.
/// 2. **Evenly**, when any item has no expected price. Weighting the ones that
///    happen to be priced would quietly load the whole bundle onto them and
///    report the rest as nearly free.
///
/// **The parts always sum to the total, exactly.** Money is integer minor
/// units (hard rule 4), so a proportional split leaves a remainder of a few
/// pence; it is handed out one unit at a time to the largest parts rather than
/// dropped, because an order whose lines do not add up to what the buyer paid
/// is a reconciliation nobody can close.
final class BundleAllocation {
  const BundleAllocation._();

  /// Split [total] across [weights], one part per weight, in the same order.
  ///
  /// A null weight is an item with no expected price — its presence switches
  /// the whole bundle to an even split.
  static List<Money> across(Money total, List<Money?> weights) {
    final String currency = total.currency;
    final int count = weights.length;

    if (count == 0) return const <Money>[];
    if (count == 1) return <Money>[total];

    final bool allKnown = weights.every((Money? weight) => weight != null);
    final int weightTotal = allKnown
        ? weights.fold(0, (int running, Money? w) => running + w!.minor)
        : 0;

    final List<int> shares = allKnown && weightTotal > 0
        ? <int>[
            for (final Money? weight in weights)
              (total.minor * weight!.minor) ~/ weightTotal,
          ]
        : <int>[for (int i = 0; i < count; i++) total.minor ~/ count];

    return _settle(shares, total.minor, weights, currency);
  }

  /// Hand the rounding remainder out so the parts add up to the whole.
  ///
  /// Largest part first: a penny on the biggest line is invisible, and on the
  /// smallest one it can be a measurable share of it.
  static List<int> _order(List<int> shares) {
    final List<int> indexes = <int>[for (int i = 0; i < shares.length; i++) i]
      ..sort((int a, int b) => shares[b].compareTo(shares[a]));

    return indexes;
  }

  static List<Money> _settle(
    List<int> shares,
    int total,
    List<Money?> weights,
    String currency,
  ) {
    final List<int> settled = List<int>.of(shares);
    final List<int> order = _order(shares);

    int remainder = total - shares.fold(0, (int a, int b) => a + b);
    int cursor = 0;

    // A negative total (never written today, but the type allows one) walks
    // the same way in the other direction rather than looping forever.
    final int step = remainder.isNegative ? -1 : 1;

    while (remainder != 0 && order.isNotEmpty) {
      settled[order[cursor % order.length]] += step;
      remainder -= step;
      cursor += 1;
    }

    return <Money>[for (final int share in settled) Money(share, currency)];
  }
}
