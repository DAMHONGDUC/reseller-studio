import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The app's semantic glyph registry.
///
/// Call sites ask for what an icon means. This file alone decides whether the
/// glyph comes from Flutter's Material Icons or the Material Symbols font.
final class AppIconConstant {
  /// Financial institution or account balance.
  static const IconData accountBalance = Symbols.account_balance_rounded;

  /// Wallet balance or available funds.
  static const IconData accountBalanceWallet =
      Symbols.account_balance_wallet_rounded;

  /// Workspace or account hierarchy.
  static const IconData accountTree = Symbols.account_tree_rounded;

  /// Remove the current record.
  static const IconData delete = Icons.delete_outline_rounded;

  /// Open additional actions.
  static const IconData moreVert = Icons.more_vert_rounded;

  /// Add a record represented as a box.
  static const IconData addBox = Symbols.add_box_rounded;

  /// Create or add a record.
  static const IconData add = Symbols.add_rounded;

  /// Move a record into the archive.
  static const IconData archive = Symbols.archive_rounded;

  /// Continue to the next step.
  static const IconData arrowForward = Symbols.arrow_forward_rounded;

  /// Return an assigned item or order.
  static const IconData assignmentReturn = Symbols.assignment_return_rounded;

  /// Repeat or renew an operation.
  static const IconData autorenew = Symbols.autorenew_rounded;

  /// Identify a team member or account.
  static const IconData badge = Symbols.badge_rounded;

  /// Open chart-based analytics.
  static const IconData barChart = Symbols.bar_chart_rounded;

  /// Scan a product barcode.
  static const IconData barcodeScanner = Symbols.barcode_scanner_rounded;

  /// Highlight a quick or automated action.
  static const IconData bolt = Symbols.bolt_rounded;

  /// Calculate a financial value.
  static const IconData calculate = Symbols.calculate_rounded;

  /// Select or view a calendar date.
  static const IconData calendarMonth = Symbols.calendar_month_rounded;

  /// Switch between device cameras.
  static const IconData cameraswitch = Symbols.cameraswitch_rounded;

  /// Represent an inventory category.
  static const IconData category = Symbols.category_rounded;

  /// Confirm a completed or selected state.
  static const IconData checkCircle = Symbols.check_circle_rounded;

  /// Confirm a choice or action.
  static const IconData check = Symbols.check_rounded;

  /// Open the detail for a row.
  static const IconData chevronRight = Symbols.chevron_right_rounded;

  /// Close or dismiss the current surface.
  static const IconData close = Symbols.close_rounded;

  /// Copy content to the clipboard.
  static const IconData contentCopy = Symbols.content_copy_rounded;

  /// Select or describe appearance contrast.
  static const IconData contrast = Symbols.contrast_rounded;

  /// Represent a card payment method.
  static const IconData creditCard = Symbols.credit_card_rounded;

  /// Convert or exchange currencies.
  static const IconData currencyExchange = Symbols.currency_exchange_rounded;

  /// Represent stored application data.
  static const IconData database = Symbols.database_rounded;

  /// Permanently remove a record.
  static const IconData deleteForever = Symbols.delete_forever_rounded;

  /// Represent a document or description.
  static const IconData description = Symbols.description_rounded;

  /// Represent mileage or vehicle travel.
  static const IconData directionsCar = Symbols.directions_car_rounded;

  /// Download or export content.
  static const IconData download = Symbols.download_rounded;

  /// Edit an existing record.
  static const IconData edit = Symbols.edit_rounded;

  /// Indicate an operation error.
  static const IconData error = Symbols.error_rounded;

  /// Expand a collapsed control.
  static const IconData expandMore = Symbols.expand_more_rounded;

  /// Clear an active filter.
  static const IconData filterAltOff = Symbols.filter_alt_off_rounded;

  /// Toggle the camera flashlight.
  static const IconData flashlightOn = Symbols.flashlight_on_rounded;

  /// Represent a formula or calculation.
  static const IconData function = Symbols.function_rounded;

  /// Represent legal or compliance information.
  static const IconData gavel = Symbols.gavel_rounded;

  /// Highlight a featured plan or benefit.
  static const IconData grade = Symbols.grade_rounded;

  /// Invite or add a team member.
  static const IconData groupAdd = Symbols.group_add_rounded;

  /// Represent a team or group.
  static const IconData group = Symbols.group_rounded;

  /// View past activity or changes.
  static const IconData history = Symbols.history_rounded;

  /// Open the Home destination.
  static const IconData home = Symbols.home_rounded;

  /// Indicate a pending countdown or wait.
  static const IconData hourglassBottom = Symbols.hourglass_bottom_rounded;

  /// Indicate time nearly elapsed.
  static const IconData hourglassTop = Symbols.hourglass_top_rounded;

  /// Represent connected channels or integrations.
  static const IconData hub = Symbols.hub_rounded;

  /// Represent an image or missing photo.
  static const IconData image = Symbols.image_rounded;

  /// Represent an empty inbox or queue.
  static const IconData inbox = Symbols.inbox_rounded;

  /// Show supporting information.
  static const IconData info = Symbols.info_rounded;

  /// Open or represent inventory.
  static const IconData inventory = Symbols.inventory_2_rounded;

  /// Open a downward selection menu.
  static const IconData keyboardArrowDown = Symbols.keyboard_arrow_down_rounded;

  /// Select language or regional settings.
  static const IconData language = Symbols.language_rounded;

  /// Represent shopping or marketplace activity.
  static const IconData localMall = Symbols.local_mall_rounded;

  /// Represent a price, offer, or label.
  static const IconData localOffer = Symbols.local_offer_rounded;

  /// Represent shipping or delivery.
  static const IconData localShipping = Symbols.local_shipping_rounded;

  /// Indicate a protected or locked state.
  static const IconData lock = Symbols.lock_rounded;

  /// Start the sign-in flow.
  static const IconData login = Symbols.login_rounded;

  /// Sign out of the current account.
  static const IconData logout = Symbols.logout_rounded;

  /// Mark a notification or message as read.
  static const IconData markEmailRead = Symbols.mark_email_read_rounded;

  /// Open the main or overflow menu.
  static const IconData menu = Symbols.menu_rounded;

  /// Open or represent notifications.
  static const IconData notifications = Symbols.notifications_rounded;

  /// Open content in an external destination.
  static const IconData openInNew = Symbols.open_in_new_rounded;

  /// Represent a parcel or packed order.
  static const IconData package = Symbols.package_2_rounded;

  /// Represent payments or payouts.
  static const IconData payments = Symbols.payments_rounded;

  /// Remove a member from a workspace.
  static const IconData personRemove = Symbols.person_remove_rounded;

  /// Represent a person or account.
  static const IconData person = Symbols.person_rounded;

  /// Capture a new photo.
  static const IconData photoCamera = Symbols.photo_camera_rounded;

  /// Choose an existing photo.
  static const IconData photoLibrary = Symbols.photo_library_rounded;

  /// Represent a sale or checkout.
  static const IconData pointOfSale = Symbols.point_of_sale_rounded;

  /// Change or review a listing price.
  static const IconData priceChange = Symbols.price_change_rounded;

  /// Mark an item as high priority.
  static const IconData priorityHigh = Symbols.priority_high_rounded;

  /// Represent public or global visibility.
  static const IconData public = Symbols.public_rounded;

  /// Scan a QR code.
  static const IconData qrCodeScanner = Symbols.qr_code_scanner_rounded;

  /// Indicate an unselected single-choice option.
  static const IconData radioButtonUnchecked =
      Symbols.radio_button_unchecked_rounded;

  /// Represent a detailed receipt or report.
  static const IconData receiptLong = Symbols.receipt_long_rounded;

  /// Represent a receipt or expense proof.
  static const IconData receipt = Symbols.receipt_rounded;

  /// Reply to a message or offer.
  static const IconData reply = Symbols.reply_rounded;

  /// Restart a setup or operation.
  static const IconData restartAlt = Symbols.restart_alt_rounded;

  /// Restore a removed or previous record.
  static const IconData restore = Symbols.restore_rounded;

  /// Represent launch or getting started.
  static const IconData rocketLaunch = Symbols.rocket_launch_rounded;

  /// Represent savings or profit.
  static const IconData savings = Symbols.savings_rounded;

  /// Represent a scheduled or timed state.
  static const IconData schedule = Symbols.schedule_rounded;

  /// Represent development or experimental data.
  static const IconData science = Symbols.science_rounded;

  /// Indicate that search found no results.
  static const IconData searchOff = Symbols.search_off_rounded;

  /// Search across application records.
  static const IconData search = Symbols.search_rounded;

  /// Represent a listing or sale tag.
  static const IconData sell = Symbols.sell_rounded;

  /// Open application settings.
  static const IconData settings = Symbols.settings_rounded;

  /// Represent a storage shelf or location.
  static const IconData shelves = Symbols.shelves;

  /// Represent security or protection.
  static const IconData shield = Symbols.shield_rounded;

  /// Represent an order or shopping purchase.
  static const IconData shoppingBag = Symbols.shopping_bag_rounded;

  /// Represent a marketplace or storefront.
  static const IconData storefront = Symbols.storefront_rounded;

  /// Open or represent a summary report.
  static const IconData summarize = Symbols.summarize_rounded;

  /// Reject or rate an outcome negatively.
  static const IconData thumbDown = Symbols.thumb_down_rounded;

  /// Approve or rate an outcome positively.
  static const IconData thumbUp = Symbols.thumb_up_rounded;

  /// Explore sourcing opportunities.
  static const IconData travelExplore = Symbols.travel_explore_rounded;

  /// Represent improving performance or growth.
  static const IconData trendingUp = Symbols.trending_up_rounded;

  /// Open filters or adjustable controls.
  static const IconData tune = Symbols.tune_rounded;

  /// Return a record from the archive.
  static const IconData unarchive = Symbols.unarchive_rounded;

  /// Represent a warehouse or stock location.
  static const IconData warehouse = Symbols.warehouse_rounded;

  /// Warn about a risky or incomplete state.
  static const IconData warning = Symbols.warning_rounded;

  /// Represent a premium workspace or plan.
  static const IconData workspacePremium = Symbols.workspace_premium_rounded;
}
