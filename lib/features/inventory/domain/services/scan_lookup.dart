import '../entities/item.dart';
import '../entities/scan_match.dart';
import '../entities/storage_location.dart';

/// Turns a scanned code into what it names (plan §7).
///
/// **Item first, then location.** A seller who printed an item's SKU on a bin
/// label meant the item. Barcode and SKU are both tried, so a code typed into
/// the wrong box still finds its item.
///
/// **A UPC-A and its EAN-13 spelling are one code.** iOS reads a UPC-A label
/// as thirteen digits with a leading zero, Android as twelve, so an item saved
/// on one phone would not be found from the other.
final class ScanLookup {
  static final RegExp _digits = RegExp(r'^\d+$');

  static ScanMatch resolve(
    String code, {
    required List<Item> items,
    required List<StorageLocation> locations,
  }) {
    final Set<String> spellings = _spellings(code.trim());
    final Item? item = items
        .where(
          (Item row) =>
              !row.isDeleted &&
              (spellings.contains(row.barcode) || spellings.contains(row.sku)),
        )
        .firstOrNull;
    final StorageLocation? location = locations
        .where(
          (StorageLocation row) =>
              !row.isDeleted && spellings.contains(row.barcode),
        )
        .firstOrNull;

    if (item != null) return ScanMatchItem(code, item);

    if (location != null) {
      return ScanMatchLocation(code, location, <Item>[
        for (final Item row in items)
          if (!row.isDeleted &&
              row.locationId == location.id &&
              row.status.isOnHand)
            row,
      ]);
    }

    return ScanMatchNone(code);
  }

  /// [code] and, for a UPC-A, its other spelling. Empty for an empty code, so
  /// a blank read never matches a record with no barcode.
  static Set<String> _spellings(String code) {
    if (code.isEmpty) return const <String>{};

    if (!_digits.hasMatch(code)) return <String>{code};

    return <String>{
      code,
      if (code.length == 12) '0$code',
      if (code.length == 13 && code.startsWith('0')) code.substring(1),
    };
  }
}
