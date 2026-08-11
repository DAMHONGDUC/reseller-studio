import '../../../listings/domain/enums/listing_status.dart';

/// Where stock comes from — a thrift store, an estate sale, a wholesaler.
///
/// **Only [name] is required** (plan §28). A seller adding a source mid-hunt
/// types the shop name and moves on; the address and phone are for the ones
/// worth going back to.
///
/// The reason this entity exists at all is the last step of the plan's
/// lifecycle: *source better*. Without it, the app can say what sold and not
/// where to find more of it.
class Source {
  const Source({
    required this.id,
    required this.name,
    required this.createdAt,
    this.type,
    this.address,
    this.phone,
    this.website,
    this.notes,
    this.deletedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final SourceType? type;
  final String? address;
  final String? phone;
  final String? website;
  final String? notes;

  /// Soft delete (hard rule 15) — hard-deleting a source orphans every
  /// purchase pointing at it and destroys the ROI history that justifies the
  /// whole Sourcing feature.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
}
