import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../inventory/domain/entities/item_category.dart';
import '../../../inventory/domain/entities/storage_location.dart';
import '../../../inventory/domain/repositories/catalog_repository.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../listings/domain/repositories/listing_repository.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/repositories/offer_repository.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../../sourcing/domain/entities/purchase.dart';
import '../../../sourcing/domain/entities/source.dart';
import '../../../sourcing/domain/repositories/sourcing_repository.dart';
import '../mock_dataset.dart';

/// Writes the demo business into whatever backend the repositories point at.
///
/// **This is not the mock-data switch and does not replace it.** That switch
/// swaps the repositories for in-memory ones and nothing is ever written; this
/// takes the same seed and pushes it through the *real* ones, so a freshly
/// created workspace has something in it. A demo against an empty account
/// shows five empty tabs, which is the app failing to make its own case.
///
/// **Every row keeps the seed's own dates.** The DTOs write `createdAt` from
/// the entity rather than a server timestamp, which is what makes the seeded
/// business look lived-in: listings that went stale weeks ago, an order that
/// shipped late, an offer about to lapse. Stamping them all with "now" would
/// empty Home's Needs Attention block, which is the screen worth demoing.
///
/// It is also the only thing that exercises every live write path in one go —
/// so a failure here is a real bug in `data/`, found before a seller finds it.
class DemoDataSeeder {
  const DemoDataSeeder({
    required this.items,
    required this.listings,
    required this.orders,
    required this.offers,
    required this.expenses,
    required this.categories,
    required this.locations,
    required this.sources,
    required this.purchases,
  });

  final ItemRepository items;
  final ListingRepository listings;
  final OrderRepository orders;
  final OfferRepository offers;
  final ExpenseRepository expenses;
  final CategoryRepository categories;
  final LocationRepository locations;
  final SourceRepository sources;
  final PurchaseRepository purchases;

  /// Writes the whole dataset and returns how many documents it wrote.
  ///
  /// **Catalogue first, then the chain that points at it** — categories and
  /// locations, then sources, purchases, items, and finally what refers to an
  /// item. Firestore enforces no relationship, so the order buys nothing
  /// technically; it means a run that fails halfway leaves a business whose
  /// remaining rows still resolve, rather than orders pointing at items that
  /// were never written.
  ///
  /// Ids come from the seed, and every write is an upsert on that id, so
  /// running it twice replaces the demo business rather than doubling it.
  Future<int> seed(MockDataset dataset) async {
    int written = 0;

    for (final ItemCategory category in dataset.categories) {
      await categories.save(category);
      written++;
    }

    for (final StorageLocation location in dataset.locations) {
      await locations.save(location);
      written++;
    }

    for (final Source source in dataset.sources) {
      await sources.save(source);
      written++;
    }

    for (final Purchase purchase in dataset.purchases) {
      await purchases.save(purchase);
      written++;
    }

    await items.saveAll(dataset.items);
    written += dataset.items.length;

    await listings.saveAll(dataset.listings);
    written += dataset.listings.length;

    for (final Order order in dataset.orders) {
      await orders.save(order);
      written++;
    }

    for (final Offer offer in dataset.offers) {
      await offers.save(offer);
      written++;
    }

    for (final Expense expense in dataset.expenses) {
      await expenses.save(expense);
      written++;
    }

    SdLogger.action(
      LogTagConstant.workspace,
      'Demo data seeded',
      <String, Object>{
        'documents': written,
        'items': dataset.items.length,
        'orders': dataset.orders.length,
      },
    );

    return written;
  }
}
