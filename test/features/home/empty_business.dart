import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/providers.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/offers/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';

/// A workspace with nothing in it — every source empty, not merely filtered.
///
/// Shared because two Home tests need it, and the second copy is the trigger.
/// **Every source, not only the one under test**: leaving `listingsProvider`
/// seeded made the checklist report a step done that a new account has not
/// taken.
List<Override> emptyBusiness() => <Override>[
  itemsProvider.overrideWith(
    (Ref ref) => Stream<List<Item>>.value(const <Item>[]),
  ),
  ordersProvider.overrideWith(
    (Ref ref) => Stream<List<Order>>.value(const <Order>[]),
  ),
  offersProvider.overrideWith(
    (Ref ref) => Stream<List<Offer>>.value(const <Offer>[]),
  ),
  listingsProvider.overrideWith(
    (Ref ref) => Stream<List<Listing>>.value(const <Listing>[]),
  ),
];
