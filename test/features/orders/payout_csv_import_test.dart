import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_csv_import.dart';

/// Reading a marketplace's own payout export.
///
/// **The file is the fastest honest way to get the figures in** — every
/// platform shows the seller what it paid, and this app measures rather than
/// estimates (hard rule 3). It is a file the seller hands over, not a
/// connection (hard rule 10), so the risk is not a token leaking; it is a
/// column read wrong and money written that nobody typed. These pin the
/// reading.
void main() {
  const String usd = 'USD';

  Money usdOf(int minor) => Money(minor, usd);

  Order orderOf({required String id, String? externalOrderId, Money? payout}) =>
      Order(
        id: id,
        status: OrderStatus.delivered,
        lines: const <OrderLine>[],
        salePrice: const Money(10000, usd),
        orderedAt: DateTime(2026, 3, 1),
        externalOrderId: externalOrderId,
        payout: payout,
      );

  group('finding the columns', () {
    test('reads a header wherever the export puts the two columns', () {
      const String csv =
          'Order creation date,Buyer name,Order earnings,Order ID\n'
          '2026-03-01,Someone,86.75,11-12874-59921\n';

      final PayoutCsvResult result = PayoutCsvImport.parse(csv, currency: usd);

      expect(result.isReadable, isTrue);
      expect(result.orderIdColumn, 'Order ID');
      expect(result.payoutColumn, 'Order earnings');
      expect(result.rows.single.externalOrderId, '11-12874-59921');
      expect(result.rows.single.payout, usdOf(8675));
    });

    test('skips the metadata an export opens with', () {
      const String csv =
          'Seller: someone\n'
          'Date range: 1 Mar 2026 - 31 Mar 2026\n'
          '\n'
          'Order ID,Order earnings\n'
          'A-1,42.00\n';

      expect(PayoutCsvImport.parse(csv, currency: usd).rows, hasLength(1));
    });

    test('prefers the earnings column over a vaguer amount', () {
      const String csv = 'Order ID,Amount,Order earnings\nA-1,999.00,42.00\n';

      final PayoutCsvResult result = PayoutCsvImport.parse(csv, currency: usd);

      expect(result.payoutColumn, 'Order earnings');
      expect(result.rows.single.payout, usdOf(4200));
    });

    test('a file with neither column is unreadable, not empty', () {
      const String csv = 'Item,Price\nJacket,42.00\n';

      expect(PayoutCsvImport.parse(csv, currency: usd).isReadable, isFalse);
    });
  });

  group('reading the cells', () {
    test('takes a currency symbol, a separator and a quoted comma', () {
      const String csv =
          'Order ID,Order earnings\n'
          '"A-1","\$1,234.56"\n';

      expect(
        PayoutCsvImport.parse(csv, currency: usd).rows.single.payout,
        usdOf(123456),
      );
    });

    test("accountants' parentheses are a negative", () {
      expect(PayoutCsvImport.amountOf('(12.34)', usd), usdOf(-1234));
    });

    test('a row with no amount is skipped, never read as zero', () {
      const String csv = 'Order ID,Order earnings\nA-1,\nA-2,42.00\n';

      final PayoutCsvResult result = PayoutCsvImport.parse(csv, currency: usd);

      // Zero would claim the platform paid nothing, which is the one thing
      // this import must never write (hard rule 5).
      expect(result.rows, hasLength(1));
      expect(result.skipped, 1);
    });

    test('a quoted field may hold a line break', () {
      const String csv =
          'Order ID,Note,Order earnings\n'
          '"A-1","two\nlines",42.00\n';

      expect(PayoutCsvImport.parse(csv, currency: usd).rows, hasLength(1));
    });
  });

  group('matching it to the business', () {
    test('lines rows up by the platform order number, ignoring case', () {
      final List<Order> orders = <Order>[
        orderOf(id: 'ord-1', externalOrderId: '11-12874-59921'),
        orderOf(id: 'ord-2', externalOrderId: 'ETSY-8827301'),
      ];

      final PayoutCsvMatch match = PayoutCsvImport.against(
        orders,
        <PayoutCsvRow>[
          PayoutCsvRow(externalOrderId: '11-12874-59921 ', payout: usdOf(8675)),
          PayoutCsvRow(externalOrderId: 'etsy-8827301', payout: usdOf(7017)),
        ],
      );

      expect(match.payoutsByOrderId, <String, Money>{
        'ord-1': usdOf(8675),
        'ord-2': usdOf(7017),
      });
      expect(match.unmatched, isEmpty);
    });

    test('leaves a settled order alone', () {
      // The file covers a whole period and names orders dealt with weeks ago;
      // rewriting one would overwrite a figure the seller may have corrected.
      final List<Order> orders = <Order>[
        orderOf(id: 'ord-1', externalOrderId: 'A-1', payout: usdOf(9000)),
      ];

      final PayoutCsvMatch match = PayoutCsvImport.against(
        orders,
        <PayoutCsvRow>[PayoutCsvRow(externalOrderId: 'A-1', payout: usdOf(1))],
      );

      expect(match.payoutsByOrderId, isEmpty);
      expect(match.unmatched, hasLength(1));
    });

    test('an order this business does not have is reported, not dropped', () {
      final PayoutCsvMatch match = PayoutCsvImport.against(
        <Order>[orderOf(id: 'ord-1', externalOrderId: 'A-1')],
        <PayoutCsvRow>[
          PayoutCsvRow(externalOrderId: 'B-2', payout: usdOf(500)),
        ],
      );

      expect(match.matchedCount, 0);
      expect(match.unmatched.single.externalOrderId, 'B-2');
    });

    test('an order with no platform number can never be matched', () {
      // A cash sale has no external id, so an import must not guess at one.
      final PayoutCsvMatch match = PayoutCsvImport.against(
        <Order>[orderOf(id: 'ord-1')],
        <PayoutCsvRow>[PayoutCsvRow(externalOrderId: '', payout: usdOf(500))],
      );

      expect(match.payoutsByOrderId, isEmpty);
    });
  });
}
