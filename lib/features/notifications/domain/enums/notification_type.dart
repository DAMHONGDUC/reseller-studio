/// What a notification is about (plan §22).
///
/// **An unknown code maps to [unknown], never to a neighbour** — a document
/// written by a newer build must render as one honest line rather than claim
/// to be whatever value happens to sit next to it in this list
/// (`docs/rules/BACKEND.md`).
enum NotificationType {
  /// An order arrived. The one a seller most wants on their lock screen.
  orderCreated,

  /// A buyer made an offer. Offers expire, which is why it is a push and not
  /// a row they might see tomorrow.
  offerReceived,

  /// The daily digest: orders past their ship-by date.
  shipmentsDue,

  /// The daily digest: listings that have been up longer than this
  /// workspace's own threshold.
  staleInventory,

  /// The daily digest: not enough left on the shelf to sell. The one
  /// reminder that points at Sourcing rather than at a record.
  lowInventory,

  /// Somebody joined the business (plan §22's "team activity").
  memberJoined,

  unknown;

  /// Whether one line stands for several rows rather than one record.
  ///
  /// The digest types carry a count and open a list; the rest name a record
  /// and open it. That is the whole difference, and it is what decides which
  /// ARB key renders the row.
  bool get isDigest =>
      this == NotificationType.shipmentsDue ||
      this == NotificationType.staleInventory ||
      this == NotificationType.lowInventory;
}
