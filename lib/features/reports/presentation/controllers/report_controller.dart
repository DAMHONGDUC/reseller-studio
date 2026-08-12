import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../expenses/providers.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/providers.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/providers.dart';
import '../../domain/services/csv_builder.dart';

/// Which report is being exported.
enum ReportKind {
  sales,
  inventory,
  expenses;

  String get fileStem => switch (this) {
    ReportKind.sales => 'sales',
    ReportKind.inventory => 'inventory',
    ReportKind.expenses => 'expenses',
  };
}

/// Exporting the seller's own data as CSV (plan §19).
///
/// **CSV, not PDF, and that is the right first format.** A reseller's
/// year-end goes to an accountant or into a spreadsheet, and both want rows
/// they can sum — a PDF is a picture of the numbers.
///
/// Money is written as a plain decimal with no symbol and no thousands
/// separator: a spreadsheet parses `19.99` and does not parse `$19.99`. The
/// currency gets its own column so the figure is still unambiguous.
class ReportController extends Notifier<bool> {
  /// True while a file is being written and handed to the share sheet.
  @override
  bool build() => false;

  /// Builds the file and opens the system share sheet.
  ///
  /// The file goes to the temporary directory: it is a copy of data the app
  /// already holds, the seller sends it somewhere immediately, and keeping it
  /// would mean managing an export folder nobody asked for.
  Future<void> export(ReportKind kind) async {
    state = true;
    AppLogger.action('Export report', <String, Object>{'kind': kind.name});
    AppAnalytics.instance.reportExported(kind: kind.name);

    try {
      final String csv = switch (kind) {
        ReportKind.sales => _salesCsv(),
        ReportKind.inventory => _inventoryCsv(),
        ReportKind.expenses => _expensesCsv(),
      };

      // `Directory.systemTemp` rather than `path_provider`: it is the same
      // per-app temporary directory on both platforms, and it needs no extra
      // plugin for a file that exists for the length of a share sheet.
      final Directory directory = Directory.systemTemp;
      final String stamp = DateTimeUtils.isoDate(DateTime.now());
      final File file = File(
        '${directory.path}/seller-os-${kind.fileStem}-$stamp.csv',
      );

      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          subject: 'Seller OS — ${kind.fileStem} export',
        ),
      );

      AppLogger.info('Report exported', <String, Object>{
        'kind': kind.name,
        'bytes': csv.length,
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to export report',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'kind': kind.name},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// One row per order line, not per order.
  ///
  /// A line is what an accountant reconciles: the item, what it cost, what it
  /// sold for. An order-level row would hide a two-item sale's economics
  /// behind one total.
  String _salesCsv() {
    final List<Order> orders =
        ref.read(ordersProvider).value ?? const <Order>[];
    final List<List<String>> rows = <List<String>>[];

    for (final Order order in orders) {
      for (final OrderLine line in order.lines) {
        rows.add(<String>[
          order.id,
          DateTimeUtils.isoDate(order.orderedAt),
          order.marketplace.displayName,
          order.status.name,
          line.title,
          '${line.quantity}',
          _major(line.unitPrice),
          _major(line.unitCost),
          _major(order.fees),
          _major(order.shippingCost),
          _major(order.payout),
          order.salePrice.currency,
        ]);
      }
    }

    return CsvBuilder.build(
      headers: const <String>[
        'Order ID',
        'Date',
        'Marketplace',
        'Status',
        'Item',
        'Quantity',
        'Unit price',
        'Unit cost',
        'Order fees',
        'Shipping',
        'Payout',
        'Currency',
      ],
      rows: rows,
    );
  }

  String _inventoryCsv() {
    final List<Item> items = ref.read(itemsProvider).value ?? const <Item>[];
    final Map<String, String> categories = ref.read(categoryNamesProvider);
    final Map<String, String> locations = ref.read(locationPathsProvider);

    return CsvBuilder.build(
      headers: const <String>[
        'Item ID',
        'Title',
        'Status',
        'Quantity',
        'SKU',
        'Barcode',
        'Category',
        'Location',
        'Cost',
        'Asking price',
        'Purchased',
        'Listed',
        'Sold',
      ],
      rows: items
          .map(
            (Item item) => <String>[
              item.id,
              item.title,
              item.status.name,
              '${item.quantity}',
              item.sku ?? '',
              item.barcode ?? '',
              categories[item.categoryId] ?? '',
              locations[item.locationId] ?? '',
              _major(item.purchasePrice),
              _major(item.askingPrice),
              _date(item.purchaseDate),
              _date(item.listedAt),
              _date(item.soldAt),
            ],
          )
          .toList(),
    );
  }

  String _expensesCsv() {
    final List<Expense> expenses =
        ref.read(expensesProvider).value ?? const <Expense>[];

    return CsvBuilder.build(
      headers: const <String>[
        'Expense ID',
        'Date',
        'Category',
        'Amount',
        'Currency',
        'Vendor',
        'Mileage',
        'Attributed to order',
        'Notes',
      ],
      rows: expenses
          .map(
            (Expense expense) => <String>[
              expense.id,
              DateTimeUtils.isoDate(expense.date),
              ExpenseCategoryLabel.of(expense.category),
              _major(expense.amount),
              expense.amount.currency,
              expense.vendor ?? '',
              expense.mileage?.toString() ?? '',
              expense.orderId ?? '',
              expense.notes ?? '',
            ],
          )
          .toList(),
    );
  }

  /// **An unknown amount exports as an empty cell, never as 0** (hard rule 5).
  /// A zero in a spreadsheet is a number an accountant will sum; a blank is a
  /// question they will ask.
  static String _major(Money? amount) => amount?.toInputString() ?? '';

  static String _date(DateTime? value) =>
      value == null ? '' : DateTimeUtils.isoDate(value);
}

final NotifierProvider<ReportController, bool> reportControllerProvider =
    NotifierProvider<ReportController, bool>(ReportController.new);
