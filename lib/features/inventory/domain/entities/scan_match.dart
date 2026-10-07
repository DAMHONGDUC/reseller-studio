import 'item.dart';
import 'storage_location.dart';

/// What a scanned code names in this business — the answer the scan result
/// screen is drawn from.
///
/// Sealed so the screen's switch breaks when a fourth answer is added, rather
/// than falling through to "no match".
sealed class ScanMatch {
  const ScanMatch(this.code);

  /// The code exactly as the camera read it.
  final String code;
}

/// The code is an item's barcode or SKU.
final class ScanMatchItem extends ScanMatch {
  const ScanMatchItem(super.code, this.item);

  final Item item;
}

/// The code is a storage location's label, with what is on that shelf now.
final class ScanMatchLocation extends ScanMatch {
  const ScanMatchLocation(super.code, this.location, this.items);

  final StorageLocation location;

  /// On-hand items stored there; a sold item has left the shelf.
  final List<Item> items;
}

/// Nothing has the code — usually something the seller is about to add.
final class ScanMatchNone extends ScanMatch {
  const ScanMatchNone(super.code);
}
