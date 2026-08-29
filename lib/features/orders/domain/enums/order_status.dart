/// Where an order is (plan §8).
///
/// ```text
/// awaitingPayment → toShip → shipped → delivered
///                              │
///                              └→ returnRequested → returned → refunded
/// ```
enum OrderStatus {
  /// Sold, money not yet cleared. Do not ship on this.
  awaitingPayment,

  /// Paid and waiting on the seller. **This is the status the whole Orders
  /// tab exists to drain** — everything else is history.
  toShip,

  shipped,
  delivered,

  /// The buyer has asked to send it back; nothing has moved yet.
  returnRequested,

  /// Physically back with the seller. The item goes to inventory, damaged or
  /// lost — a decision the seller makes, which is why this is not terminal.
  returned,

  /// Money returned to the buyer, in part or in full.
  refunded,

  cancelled;

  /// Whether this order still needs the seller to do something.
  ///
  /// What Home's "Needs Attention" counts. `shipped` is excluded — it is with
  /// the carrier, and nagging about it every morning trains the seller to
  /// ignore the whole block.
  bool get needsAction => switch (this) {
    OrderStatus.toShip || OrderStatus.returnRequested => true,
    OrderStatus.awaitingPayment ||
    OrderStatus.shipped ||
    OrderStatus.delivered ||
    OrderStatus.returned ||
    OrderStatus.refunded ||
    OrderStatus.cancelled => false,
  };

  /// Whether this order's money counts as revenue.
  ///
  /// A cancelled order never earned anything, and a refunded one gave it
  /// back — counting either would make the analytics disagree with the payout
  /// the seller actually received.
  bool get countsAsRevenue => switch (this) {
    OrderStatus.toShip ||
    OrderStatus.shipped ||
    OrderStatus.delivered ||
    OrderStatus.returnRequested ||
    OrderStatus.returned => true,
    OrderStatus.awaitingPayment ||
    OrderStatus.refunded ||
    OrderStatus.cancelled => false,
  };
}

/// Where an offer is (plan §8).
enum OfferStatus { pending, accepted, declined, countered, expired }
