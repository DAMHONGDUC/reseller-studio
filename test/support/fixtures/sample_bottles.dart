import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';

/// One sample bottle: the label drawn in `sample_bottles/<slug>.svg` and the
/// code a scanner reads off it.
class SampleBottle {
  const SampleBottle({
    required this.slug,
    required this.title,
    required this.code,
    this.itemId,
  });

  final String slug;
  final String title;

  /// What is printed under the bars, and what an item stores.
  final String code;

  /// Null for the bottle nothing in the business has — the no-match case.
  final String? itemId;

  String get svgPath => 'test/support/fixtures/sample_bottles/$slug.svg';
}

/// Bottles with real, scannable barcodes — one per format the scanner reads
/// from retail labels, and one that matches nothing.
///
/// The SVGs are printable: point a phone at one on screen to try the scanner
/// for real. `generate.py` draws them from the same codes.
final class SampleBottles {
  static const SampleBottle perfume = SampleBottle(
    slug: 'perfume',
    title: 'Santal 33 eau de parfum — 50 ml',
    code: '5901234123457',
    itemId: 'itm-bottle-perfume',
  );

  /// A UPC-A: twelve digits stored, thirteen read on iOS.
  static const SampleBottle flask = SampleBottle(
    slug: 'flask',
    title: 'Hydro Flask wide mouth — 32 oz',
    code: '036000291452',
    itemId: 'itm-bottle-flask',
  );

  static const SampleBottle cola = SampleBottle(
    slug: 'cola',
    title: 'Coca-Cola glass bottle — 1960s',
    code: '96385074',
    itemId: 'itm-bottle-cola',
  );

  static const SampleBottle water = SampleBottle(
    slug: 'water',
    title: 'Unlisted water bottle — 750 ml',
    code: '4006381333931',
  );

  static const List<SampleBottle> all = <SampleBottle>[
    perfume,
    flask,
    cola,
    water,
  ];

  /// The location the flask sits in — `Bin A1` in the mock dataset.
  static const String flaskLocationId = 'loc-bin-a1';

  /// The three bottles the business owns, as items.
  static List<Item> items({required DateTime now, String currency = 'USD'}) =>
      <Item>[
        Item(
          id: perfume.itemId!,
          title: perfume.title,
          quantity: 1,
          status: ItemStatus.inStock,
          createdAt: now.subtract(const Duration(days: 12)),
          purchasePrice: Money(4500, currency),
          expectedPrice: Money(14000, currency),
          barcode: perfume.code,
          sku: 'BTL-0001',
        ),
        Item(
          id: flask.itemId!,
          title: flask.title,
          quantity: 1,
          status: ItemStatus.inStock,
          createdAt: now.subtract(const Duration(days: 6)),
          purchasePrice: Money(800, currency),
          expectedPrice: Money(3200, currency),
          barcode: flask.code,
          sku: 'BTL-0002',
          locationId: flaskLocationId,
        ),
        Item(
          id: cola.itemId!,
          title: cola.title,
          quantity: 1,
          status: ItemStatus.draft,
          createdAt: now.subtract(const Duration(days: 2)),
          barcode: cola.code,
          sku: 'BTL-0003',
        ),
      ];
}
