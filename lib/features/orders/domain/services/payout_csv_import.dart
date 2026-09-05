import '../../../../core/money/money.dart';
import '../entities/order.dart';

/// One row of a marketplace's payout export, reduced to what this app keeps.
///
/// **Two fields, and that is the privacy boundary.** A marketplace export can
/// carry a buyer's name and address; nothing else on the row is read, so those
/// columns are never held, logged or written (hard rule 9).
class PayoutCsvRow {
  const PayoutCsvRow({required this.externalOrderId, required this.payout});

  /// The platform's own order number, matched against `Order.externalOrderId`.
  final String externalOrderId;

  /// What that platform actually paid for the order.
  final Money payout;
}

/// What a file turned out to contain.
class PayoutCsvResult {
  const PayoutCsvResult({
    required this.rows,
    required this.skipped,
    this.orderIdColumn,
    this.payoutColumn,
  });

  const PayoutCsvResult.unreadable()
    : rows = const <PayoutCsvRow>[],
      skipped = 0,
      orderIdColumn = null,
      payoutColumn = null;

  final List<PayoutCsvRow> rows;

  /// Rows that had the columns but no usable pair in them — a heading repeated
  /// mid-file, a summary line, an order with no payout yet.
  final int skipped;

  /// The headers this file was read through, so the screen can say which two
  /// columns it used rather than asking the seller to trust it.
  final String? orderIdColumn;
  final String? payoutColumn;

  bool get isReadable => orderIdColumn != null && payoutColumn != null;
}

/// Which of this business's orders a file's rows belong to.
class PayoutCsvMatch {
  const PayoutCsvMatch({
    required this.payoutsByOrderId,
    required this.unmatched,
  });

  /// This app's order id → what the file says it paid.
  final Map<String, Money> payoutsByOrderId;

  /// Rows naming an order this business does not have, or one already settled.
  final List<PayoutCsvRow> unmatched;

  int get matchedCount => payoutsByOrderId.length;
}

/// Read a marketplace's payout export.
///
/// **The one import this app has, and it is a file the seller hands over —
/// not a connection.** There is no OAuth, no token and no sync (hard rule 10);
/// what arrives is text the seller exported themselves, which is why this is a
/// parser rather than a client.
///
/// **Columns are found by name, not by position.** eBay's Earnings report,
/// Etsy's and a spreadsheet somebody keeps by hand all put the two useful
/// values in different places, and a fixed column index turns a reordered
/// export into silently wrong money. Anything outside [orderIdAliases] and
/// [payoutAliases] is never read at all.
///
/// **The payout is the platform's own earnings figure, not its net-of-cost
/// one.** eBay's `Order earnings` is what it paid; its `Net order earnings`
/// subtracts what the seller paid for the item, which this app derives itself
/// from the purchase price and must not take twice.
final class PayoutCsvImport {
  const PayoutCsvImport._();

  /// Headers that name the platform's order number, normalised.
  static const List<String> orderIdAliases = <String>[
    'orderid',
    'ordernumber',
    'orderno',
    'salesrecordnumber',
    'transactionid',
    'referenceid',
  ];

  /// Headers that name what the platform paid, normalised.
  ///
  /// Ordered best-first: a file carrying both `Order earnings` and a vaguer
  /// `Amount` must take the earnings column.
  static const List<String> payoutAliases = <String>[
    'orderearnings',
    'netpayout',
    'payout',
    'netamount',
    'earnings',
    'netproceeds',
    'amount',
  ];

  /// How far into a file a header row may hide.
  ///
  /// Marketplace exports open with a few lines of account and date-range
  /// metadata before the real header; past this it is not that shape of file.
  static const int headerSearchRows = 20;

  static PayoutCsvResult parse(String csv, {required String currency}) {
    final List<List<String>> rows = _rows(csv);
    final int headerAt = _headerRow(rows);

    if (headerAt < 0) return const PayoutCsvResult.unreadable();

    final List<String> header = rows[headerAt];
    final int idAt = _columnFor(header, orderIdAliases);
    final int payoutAt = _columnFor(header, payoutAliases);

    if (idAt < 0 || payoutAt < 0) return const PayoutCsvResult.unreadable();

    final List<PayoutCsvRow> parsed = <PayoutCsvRow>[];
    int skipped = 0;

    for (final List<String> row in rows.skip(headerAt + 1)) {
      final String id = _cell(row, idAt);
      final Money? payout = amountOf(_cell(row, payoutAt), currency);

      if (id.isEmpty || payout == null) {
        // A blank line or a totals row, not a failure worth reporting as one.
        if (row.any((String cell) => cell.trim().isNotEmpty)) skipped++;

        continue;
      }

      parsed.add(PayoutCsvRow(externalOrderId: id, payout: payout));
    }

    return PayoutCsvResult(
      rows: parsed,
      skipped: skipped,
      orderIdColumn: header[idAt].trim(),
      payoutColumn: header[payoutAt].trim(),
    );
  }

  /// Line up a file's rows against the orders still owed a figure.
  ///
  /// **Only orders that need one.** A file covers a whole payout period and
  /// names orders that were settled weeks ago; re-writing those would overwrite
  /// a figure the seller may have corrected by hand.
  static PayoutCsvMatch against(List<Order> orders, List<PayoutCsvRow> rows) {
    final Map<String, Order> byExternalId = <String, Order>{
      for (final Order order in orders)
        if (order.needsPayout)
          if (order.externalOrderId case final String id) _key(id): order,
    };
    final Map<String, Money> matched = <String, Money>{};
    final List<PayoutCsvRow> unmatched = <PayoutCsvRow>[];

    for (final PayoutCsvRow row in rows) {
      final Order? order = byExternalId[_key(row.externalOrderId)];

      if (order == null) {
        unmatched.add(row);

        continue;
      }

      matched[order.id] = row.payout;
    }

    return PayoutCsvMatch(payoutsByOrderId: matched, unmatched: unmatched);
  }

  /// A money value as an export writes it.
  ///
  /// `Money.tryParse` takes what a seller types; a file adds a currency symbol,
  /// a thousands separator and accountants' parentheses for a negative.
  static Money? amountOf(String cell, String currency) {
    final String trimmed = cell.trim();

    if (trimmed.isEmpty) return null;

    final bool isBracketed = trimmed.startsWith('(') && trimmed.endsWith(')');
    final String digits = trimmed.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final Money? amount = Money.tryParse(digits, currency);

    if (amount == null) return null;

    return isBracketed ? Money(-amount.minor.abs(), currency) : amount;
  }

  /// Ids differ only in case and padding between an export and a screen.
  static String _key(String id) => id.trim().toLowerCase();

  /// The first row that names both columns, or -1.
  static int _headerRow(List<List<String>> rows) {
    final int limit = rows.length < headerSearchRows
        ? rows.length
        : headerSearchRows;

    for (int i = 0; i < limit; i++) {
      final bool hasBoth =
          _columnFor(rows[i], orderIdAliases) >= 0 &&
          _columnFor(rows[i], payoutAliases) >= 0;

      if (hasBoth) return i;
    }

    return -1;
  }

  /// The column whose header matches the earliest alias, or -1.
  static int _columnFor(List<String> header, List<String> aliases) {
    for (final String alias in aliases) {
      for (int i = 0; i < header.length; i++) {
        if (_normalise(header[i]) == alias) return i;
      }
    }

    return -1;
  }

  /// `Order ID`, `order_id` and `"Order Id "` are one header.
  static String _normalise(String header) =>
      header.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  static String _cell(List<String> row, int at) =>
      at < row.length ? row[at].trim() : '';

  /// Split the file into rows of cells.
  ///
  /// Written here rather than taken from a package: the shape is one quoting
  /// rule and a line break, and a dependency for it would be a decision the
  /// owner has to make about a build that already ships.
  static List<List<String>> _rows(String csv) {
    final List<List<String>> rows = <List<String>>[];
    final StringBuffer cell = StringBuffer();
    List<String> row = <String>[];
    bool inQuotes = false;

    for (int i = 0; i < csv.length; i++) {
      final String char = csv[i];

      if (inQuotes) {
        // A doubled quote inside a quoted field is one literal quote.
        if (char == '"' && i + 1 < csv.length && csv[i + 1] == '"') {
          cell.write('"');
          i++;
        } else if (char == '"') {
          inQuotes = false;
        } else {
          cell.write(char);
        }

        continue;
      }

      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (char == '\n' || char == '\r') {
        // A CRLF is one break, not two empty rows.
        if (char == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') i++;

        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }

    return rows;
  }
}
