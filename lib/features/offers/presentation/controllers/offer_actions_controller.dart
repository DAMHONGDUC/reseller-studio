import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../mock_data/providers.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../orders/providers.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';

/// Accept, decline or counter an offer (plan §8).
///
/// **Accepting creates the order**, exactly as marking an item sold does —
/// the plan's own flow is `Offer → Review → Accept → Order` (§30), and an
/// accepted offer that produced no order would vanish from every profit
/// figure in the app.
///
/// Declining and countering only move the offer. Countering is recorded
/// rather than sent: no marketplace is connected, so the app must not claim
/// to have replied to a buyer on eBay's behalf.
class OfferActionsController extends Notifier<bool> {
  /// True while a write is in flight.
  @override
  bool build() => false;

  /// Accept, and turn the offer into a sale at the offered price.
  ///
  /// The **offered** amount, not the asking price: that is what the buyer
  /// agreed to pay, and recording anything else would overstate revenue.
  Future<void> accept(Offer offer) async {
    final ItemRepository items = ref.read(itemRepositoryProvider);

    state = true;
    SdLogger.action(LogTagConstant.offer, 'Accept offer', <String, Object>{
      'offerId': offer.id,
      'amountMinor': offer.amount.minor,
      'marketplace': offer.marketplace.name,
    });

    try {
      final Item? item = await items.findById(offer.itemId);

      if (item == null) {
        // The item was deleted while the offer sat there. Recording the
        // decision is still right; inventing an order for a thing that no
        // longer exists is not.
        SdLogger.warning(
          LogTagConstant.offer,
          'Accepted an offer whose item is gone',
          <String, Object>{'offerId': offer.id, 'itemId': offer.itemId},
        );

        await _save(offer, OfferStatus.accepted);

        return;
      }

      await ref
          .read(recordSaleControllerProvider.notifier)
          .record(
            item,
            salePrice: offer.amount,
            marketplace: offer.marketplace,
            soldAt: DateTime.now(),
            buyerName: offer.buyerName,
          );

      await _save(offer, OfferStatus.accepted);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.offer,
        'Failed to accept offer',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'offerId': offer.id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> decline(Offer offer) async {
    state = true;
    SdLogger.action(LogTagConstant.offer, 'Decline offer', <String, Object>{
      'offerId': offer.id,
    });

    try {
      await _save(offer, OfferStatus.declined);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.offer,
        'Failed to decline offer',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'offerId': offer.id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Record what the seller came back with.
  ///
  /// **Recorded, not sent.** Nothing is integrated, so the app notes the
  /// counter for the seller's own records and does not pretend to have
  /// replied to the buyer.
  Future<void> counter(Offer offer, Money amount) async {
    state = true;
    SdLogger.action(LogTagConstant.offer, 'Counter offer', <String, Object>{
      'offerId': offer.id,
      'counterMinor': amount.minor,
    });

    try {
      await _save(offer, OfferStatus.countered, counterAmount: amount);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.offer,
        'Failed to counter offer',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'offerId': offer.id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> _save(Offer offer, OfferStatus status, {Money? counterAmount}) {
    final OfferRepository repository = ref.read(offerRepositoryProvider);

    return repository.save(
      offer.copyWith(
        status: status,
        counterAmount: counterAmount,
        respondedAt: DateTime.now(),
      ),
    );
  }
}

final NotifierProvider<OfferActionsController, bool>
offerActionsControllerProvider = NotifierProvider<OfferActionsController, bool>(
  OfferActionsController.new,
);
