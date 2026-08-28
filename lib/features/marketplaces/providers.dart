import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../workspace/providers.dart';
import '../mock_data/providers.dart';
import 'domain/entities/marketplace.dart';

/// Every marketplace this business has, deleted ones included.
///
/// The deleted ones stay in the stream because a past order still names one,
/// and a row reading its raw id is worse than a row reading "Depop" with the
/// platform no longer offered as a destination (hard rule 15).
final StreamProvider<List<Marketplace>> marketplacesProvider =
    StreamProvider<List<Marketplace>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<Marketplace>(
        ref,
        () => ref.watch(marketplaceRepositoryProvider).watchMarketplaces(),
      );
    });

/// The ones a seller may still list on — every picker reads this.
final Provider<List<Marketplace>> activeMarketplacesProvider =
    Provider<List<Marketplace>>((Ref ref) {
      return <Marketplace>[
        for (final Marketplace marketplace
            in ref.watch(marketplacesProvider).value ?? const <Marketplace>[])
          if (!marketplace.isDeleted) marketplace,
      ];
    });

/// Id → the name the seller gave it. What every row renders through
/// `MarketplaceLabel`.
final Provider<Map<String, String>> marketplaceNamesProvider =
    Provider<Map<String, String>>((Ref ref) {
      return <String, String>{
        for (final Marketplace marketplace
            in ref.watch(marketplacesProvider).value ?? const <Marketplace>[])
          marketplace.id: marketplace.name,
      };
    });

/// Id → what that platform takes, as a fraction of the sale.
///
/// **A planning estimate, never accounting.** A fee an order actually reported
/// is a fact and always wins — see `PayoutReconciliation.expected`.
final Provider<Map<String, double>> marketplaceFeeRatesProvider =
    Provider<Map<String, double>>((Ref ref) {
      return <String, double>{
        for (final Marketplace marketplace
            in ref.watch(marketplacesProvider).value ?? const <Marketplace>[])
          marketplace.id: marketplace.feeRate,
      };
    });
