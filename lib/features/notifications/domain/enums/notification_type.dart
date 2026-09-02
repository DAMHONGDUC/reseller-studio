import 'package:flutter/widgets.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/extensions/context_extensions.dart';

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

  /// The daily digest: orders that have to leave **today**.
  ///
  /// The one before [shipmentsDue], and the one that saves the seller money:
  /// by the time an order is past its deadline the late-shipment mark is
  /// already against their account.
  shipByToday,

  /// The daily digest: orders past their ship-by date.
  shipmentsDue,

  /// An offer is about to run out. Offers expire in hours, and an expired one
  /// is a sale that walked.
  offerExpiring,

  /// The daily digest: orders the platform has still not paid out.
  ///
  /// The only reminder that hands the seller money back rather than work.
  payoutMissing,

  /// The weekly digest: sales whose fee or cost nobody has entered, so their
  /// profit is a guess. What keeps the tax export honest.
  profitIncomplete,

  /// The tax year is closing, or its filing deadline is near.
  taxSeason,

  /// The monthly note: which source or category actually sold. The one
  /// reminder that is good news, and the last step of the plan's own chain —
  /// ANALYZE → SOURCE BETTER.
  restockWinner,

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
      this == NotificationType.shipByToday ||
      this == NotificationType.shipmentsDue ||
      this == NotificationType.offerExpiring ||
      this == NotificationType.payoutMissing ||
      this == NotificationType.profitIncomplete ||
      this == NotificationType.staleInventory ||
      this == NotificationType.lowInventory;

  /// Whether a person may turn this one off.
  ///
  /// [unknown] is not a reminder anybody chose — it is a row written by a
  /// newer build — so it is never offered as a switch.
  static List<NotificationType> get configurable => NotificationType.values
      .where((NotificationType type) => type != NotificationType.unknown)
      .toList();
}

/// How a type reads and what it wears.
///
/// The one place `domain/` may import Flutter (root `CLAUDE.md`), and it
/// carries both halves so a switch cannot drift from a second copy elsewhere —
/// the inbox row and the settings screen ask the same question and get the
/// same answer.
extension NotificationTypeDisplay on NotificationType {
  /// What the settings screen calls this reminder.
  String label(BuildContext context) => switch (this) {
    NotificationType.orderCreated => context.l10n.notificationTypeOrderCreated,
    NotificationType.offerReceived =>
      context.l10n.notificationTypeOfferReceived,
    NotificationType.shipByToday => context.l10n.notificationTypeShipByToday,
    NotificationType.shipmentsDue => context.l10n.notificationTypeShipmentsDue,
    NotificationType.offerExpiring =>
      context.l10n.notificationTypeOfferExpiring,
    NotificationType.payoutMissing =>
      context.l10n.notificationTypePayoutMissing,
    NotificationType.profitIncomplete =>
      context.l10n.notificationTypeProfitIncomplete,
    NotificationType.taxSeason => context.l10n.notificationTypeTaxSeason,
    NotificationType.restockWinner =>
      context.l10n.notificationTypeRestockWinner,
    NotificationType.staleInventory =>
      context.l10n.notificationTypeStaleInventory,
    NotificationType.lowInventory => context.l10n.notificationTypeLowInventory,
    NotificationType.memberJoined => context.l10n.notificationTypeMemberJoined,
    NotificationType.unknown => context.l10n.notificationSomethingHappened,
  };

  /// What turning it off costs, in one line. A switch with no consequence
  /// written next to it is one people turn off and then miss.
  String description(BuildContext context) => switch (this) {
    NotificationType.orderCreated =>
      context.l10n.notificationTypeOrderCreatedBody,
    NotificationType.offerReceived =>
      context.l10n.notificationTypeOfferReceivedBody,
    NotificationType.shipByToday =>
      context.l10n.notificationTypeShipByTodayBody,
    NotificationType.shipmentsDue =>
      context.l10n.notificationTypeShipmentsDueBody,
    NotificationType.offerExpiring =>
      context.l10n.notificationTypeOfferExpiringBody,
    NotificationType.payoutMissing =>
      context.l10n.notificationTypePayoutMissingBody,
    NotificationType.profitIncomplete =>
      context.l10n.notificationTypeProfitIncompleteBody,
    NotificationType.taxSeason => context.l10n.notificationTypeTaxSeasonBody,
    NotificationType.restockWinner =>
      context.l10n.notificationTypeRestockWinnerBody,
    NotificationType.staleInventory =>
      context.l10n.notificationTypeStaleInventoryBody,
    NotificationType.lowInventory =>
      context.l10n.notificationTypeLowInventoryBody,
    NotificationType.memberJoined =>
      context.l10n.notificationTypeMemberJoinedBody,
    NotificationType.unknown => context.l10n.notificationSomethingHappened,
  };

  IconData get icon => switch (this) {
    NotificationType.orderCreated => AppIconConstant.receiptLong,
    NotificationType.offerReceived ||
    NotificationType.offerExpiring => AppIconConstant.localOffer,
    NotificationType.shipByToday ||
    NotificationType.shipmentsDue => AppIconConstant.localShipping,
    NotificationType.payoutMissing => AppIconConstant.payments,
    NotificationType.profitIncomplete => AppIconConstant.calculate,
    NotificationType.taxSeason => AppIconConstant.receiptLong,
    NotificationType.restockWinner => AppIconConstant.trendingUp,
    NotificationType.staleInventory => AppIconConstant.hourglassBottom,
    NotificationType.lowInventory => AppIconConstant.inventory,
    NotificationType.memberJoined => AppIconConstant.groupAdd,
    NotificationType.unknown => AppIconConstant.notifications,
  };
}
