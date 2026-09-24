/// Where every repository in the app comes from.
///
/// One file rather than one per feature, because the answer is the same shape
/// for all of them — a `WorkspaceContext` or a guard — and a screen must never
/// reach into another feature's `data/`. Features import this; nothing imports
/// a Firestore class directly.
///
/// **There is no second backend any more.** The mock-data switch used to sit
/// here and swap all of these for in-memory fakes; it is gone, and the fakes
/// live in `test/support/fakes/` where a fake belongs. What fills a workspace
/// now is `SeedDataSeeder`, which writes real documents through these very
/// providers.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/app_config/data/repositories/fallback_app_config_repository.dart';
import '../../features/app_config/data/repositories/firestore_app_config_repository.dart';
import '../../features/app_config/domain/repositories/app_config_repository.dart';
import '../../features/auth/providers.dart';
import '../../features/carriers/data/repositories/firestore_carrier_repository.dart';
import '../../features/carriers/data/repositories/local_carrier_repository.dart';
import '../../features/carriers/domain/repositories/carrier_repository.dart';
import '../../features/expenses/data/repositories/firestore_expense_repository.dart';
import '../../features/expenses/data/repositories/local_expense_repository.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/inventory/data/repositories/firestore_catalog_repositories.dart';
import '../../features/inventory/data/repositories/firestore_item_repository.dart';
import '../../features/inventory/data/repositories/local_catalog_repositories.dart';
import '../../features/inventory/data/repositories/local_item_repository.dart';
import '../../features/inventory/domain/repositories/catalog_repository.dart';
import '../../features/inventory/domain/repositories/item_repository.dart';
import '../../features/listings/data/repositories/firestore_listing_repository.dart';
import '../../features/listings/data/repositories/local_listing_repository.dart';
import '../../features/listings/domain/repositories/listing_repository.dart';
import '../../features/marketplaces/data/repositories/firestore_marketplace_repository.dart';
import '../../features/marketplaces/data/repositories/local_marketplace_repository.dart';
import '../../features/marketplaces/domain/repositories/marketplace_repository.dart';
import '../../features/offers/data/repositories/firestore_offer_repository.dart';
import '../../features/offers/data/repositories/local_offer_repository.dart';
import '../../features/offers/domain/repositories/offer_repository.dart';
import '../../features/orders/data/repositories/firestore_order_repository.dart';
import '../../features/orders/data/repositories/local_order_repository.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/seed_data/domain/services/seed_data_seeder.dart';
import '../../features/sourcing/data/repositories/firestore_sourcing_repositories.dart';
import '../../features/sourcing/data/repositories/local_sourcing_repositories.dart';
import '../../features/sourcing/domain/repositories/sourcing_repository.dart';
import '../../features/subscription/data/repositories/revenue_cat_subscription_repository.dart';
import '../../features/subscription/data/repositories/unconfigured_subscription_repository.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/workspace/data/repositories/firestore_workspace_purge_repository.dart';
import '../../features/workspace/domain/repositories/workspace_purge_repository.dart';
import '../../features/workspace/providers.dart';
import '../account/account_kind.dart';
import '../config/app_env.dart';
import '../firestore/workspace_context.dart';
import '../local/local_database.dart';
import '../local/local_providers.dart';
import '../storage/file_uploader.dart';
import '../storage/firebase_file_uploader.dart';
import '../storage/guest_file_uploader.dart';

/// Thrown when a screen reads a repository in live mode before there is a
/// workspace to read from.
///
/// A named error rather than a null: the router keeps a user without a
/// workspace on the onboarding route, so reaching this means a screen is
/// mounted that should not be, and a message saying which repository and why
/// is the difference between a five-minute fix and an afternoon.
final class LiveRepositoryGuard {
  static Never noWorkspace(String repository) => throw StateError(
    '\$repository was read with no active workspace. Sign in and finish '
    'workspace setup.',
  );
}

/// Which store a repository reads, decided in one place.
///
/// **The whole seam between guest mode and an account**
/// (`docs/rules/GUEST_MODE.md`). Every provider below goes through it, so a
/// repository added without a guest half fails to compile rather than
/// silently throwing the first time a signed-out seller opens its screen.
final class RepositoryChoice {
  static T between<T>(
    Ref ref, {
    required String name,
    required T Function(LocalDatabase db, String currency) guest,
    required T Function(WorkspaceContext context) linked,
  }) {
    if (ref.watch(accountKindProvider) == AccountKind.guest) {
      return guest(
        ref.watch(localDatabaseProvider),
        ref.watch(workspaceCurrencyProvider),
      );
    }

    final WorkspaceContext? context = ref.watch(workspaceContextProvider);

    if (context == null) LiveRepositoryGuard.noWorkspace(name);

    return linked(context);
  }
}

final Provider<ItemRepository> itemRepositoryProvider =
    Provider<ItemRepository>(
      (Ref ref) => RepositoryChoice.between<ItemRepository>(
        ref,
        name: 'ItemRepository',
        guest: (LocalDatabase db, String currency) =>
            LocalItemRepository(db, currency: currency),
        linked: FirestoreItemRepository.new,
      ),
    );

final Provider<OrderRepository> orderRepositoryProvider =
    Provider<OrderRepository>(
      (Ref ref) => RepositoryChoice.between<OrderRepository>(
        ref,
        name: 'OrderRepository',
        guest: (LocalDatabase db, String currency) =>
            LocalOrderRepository(db, currency: currency),
        linked: FirestoreOrderRepository.new,
      ),
    );

final Provider<OfferRepository> offerRepositoryProvider =
    Provider<OfferRepository>(
      (Ref ref) => RepositoryChoice.between<OfferRepository>(
        ref,
        name: 'OfferRepository',
        guest: (LocalDatabase db, String currency) =>
            LocalOfferRepository(db, currency: currency),
        linked: FirestoreOfferRepository.new,
      ),
    );

final Provider<MarketplaceRepository> marketplaceRepositoryProvider =
    Provider<MarketplaceRepository>(
      (Ref ref) => RepositoryChoice.between<MarketplaceRepository>(
        ref,
        name: 'MarketplaceRepository',
        guest: (LocalDatabase db, String _) => LocalMarketplaceRepository(db),
        linked: FirestoreMarketplaceRepository.new,
      ),
    );

final Provider<CarrierRepository> carrierRepositoryProvider =
    Provider<CarrierRepository>(
      (Ref ref) => RepositoryChoice.between<CarrierRepository>(
        ref,
        name: 'CarrierRepository',
        guest: (LocalDatabase db, String _) => LocalCarrierRepository(db),
        linked: FirestoreCarrierRepository.new,
      ),
    );

final Provider<ListingRepository> listingRepositoryProvider =
    Provider<ListingRepository>(
      (Ref ref) => RepositoryChoice.between<ListingRepository>(
        ref,
        name: 'ListingRepository',
        guest: (LocalDatabase db, String currency) =>
            LocalListingRepository(db, currency: currency),
        linked: FirestoreListingRepository.new,
      ),
    );

final Provider<SourceRepository> sourceRepositoryProvider =
    Provider<SourceRepository>(
      (Ref ref) => RepositoryChoice.between<SourceRepository>(
        ref,
        name: 'SourceRepository',
        guest: (LocalDatabase db, String _) => LocalSourceRepository(db),
        linked: FirestoreSourceRepository.new,
      ),
    );

final Provider<PurchaseRepository> purchaseRepositoryProvider =
    Provider<PurchaseRepository>(
      (Ref ref) => RepositoryChoice.between<PurchaseRepository>(
        ref,
        name: 'PurchaseRepository',
        guest: (LocalDatabase db, String currency) =>
            LocalPurchaseRepository(db, currency: currency),
        linked: FirestorePurchaseRepository.new,
      ),
    );

/// Where photos and receipts go.
///
/// A widget test keeps the local path rather than uploading — there is no
/// Firebase project behind it — but that swap lives in `test/support/fakes/`,
/// not here.
final Provider<FileUploader> fileUploaderProvider = Provider<FileUploader>(
  (Ref ref) => RepositoryChoice.between<FileUploader>(
    ref,
    name: 'FileUploader',
    // A guest has no bucket and no rules to satisfy, so the file is copied
    // into app-private storage and the record points at the copy.
    guest: (LocalDatabase db, String _) => const GuestFileUploader(),
    linked: (WorkspaceContext context) =>
        FirebaseFileUploader(FirebaseStorage.instance, context.workspaceId),
  ),
);

final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
      (Ref ref) => RepositoryChoice.between<CategoryRepository>(
        ref,
        name: 'CategoryRepository',
        guest: (LocalDatabase db, String _) => LocalCategoryRepository(db),
        linked: FirestoreCategoryRepository.new,
      ),
    );

final Provider<LocationRepository> locationRepositoryProvider =
    Provider<LocationRepository>(
      (Ref ref) => RepositoryChoice.between<LocationRepository>(
        ref,
        name: 'LocationRepository',
        guest: (LocalDatabase db, String _) => LocalLocationRepository(db),
        linked: FirestoreLocationRepository.new,
      ),
    );

final Provider<ExpenseRepository> expenseRepositoryProvider =
    Provider<ExpenseRepository>(
      (Ref ref) => RepositoryChoice.between<ExpenseRepository>(
        ref,
        name: 'ExpenseRepository',
        guest: (LocalDatabase db, String currency) =>
            LocalExpenseRepository(db, currency: currency),
        linked: FirestoreExpenseRepository.new,
      ),
    );

/// Billing is the one repository with a **third** state.
///
/// The others are Firestore, and a read without a workspace is a
/// programming error. Here, live mode without a RevenueCat key is the app's
/// normal condition until the owner sets it up — so it gets a real
/// implementation that puts everyone on Free rather than a guard that throws.
/// It also needs no `WorkspaceContext`: entitlement belongs to the account,
/// not to a workspace.
final Provider<SubscriptionRepository> subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((Ref ref) {
      if (!AppEnv.hasBillingConfig) return UnconfiguredSubscriptionRepository();

      return RevenueCatSubscriptionRepository();
    });

/// The product's own switches, read by every client and written by none.
///
/// **A build with no Firebase gets the fallback rather than a crash.**
/// `FirebaseFirestore.instance` throws `[core/no-app]` when
/// `Firebase.initializeApp` has not run, and this provider is read before the
/// first frame of a gated screen — the same reason `authUserProvider` checks
/// `firebaseReadyProvider` first. It takes no `WorkspaceContext`: the flag is
/// the product's, not a business's.
///
/// **A test does not fake it either.** `Firebase.apps` is empty there, so
/// this already hands back [FallbackAppConfigRepository] — the same
/// `AppConfig.fallback` a fake would return.
final Provider<AppConfigRepository> appConfigRepositoryProvider =
    Provider<AppConfigRepository>((Ref ref) {
      if (!ref.watch(firebaseReadyProvider)) {
        return const FallbackAppConfigRepository();
      }

      return FirestoreAppConfigRepository(FirebaseFirestore.instance);
    });

/// Empties the open workspace of every business record.
///
/// **Developer-only**, and it is the seeder's opposite number — the card that
/// reads it lives in the same Developer section on More, behind the same grant.
final Provider<WorkspacePurgeRepository> workspacePurgeRepositoryProvider =
    Provider<WorkspacePurgeRepository>((Ref ref) {
      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) {
        LiveRepositoryGuard.noWorkspace('WorkspacePurgeRepository');
      }

      return FirestoreWorkspacePurgeRepository(context);
    });

/// Writes the seed business through the same repositories every screen reads.
///
/// Built from the providers above rather than from the Firestore classes, so
/// seeding drives the exact write paths a seller's own taps drive — which is
/// what makes it the fastest way to find out whether `data/` works.
final Provider<SeedDataSeeder> seedDataSeederProvider =
    Provider<SeedDataSeeder>(
      (Ref ref) => SeedDataSeeder(
        purge: ref.watch(workspacePurgeRepositoryProvider),
        items: ref.watch(itemRepositoryProvider),
        listings: ref.watch(listingRepositoryProvider),
        orders: ref.watch(orderRepositoryProvider),
        offers: ref.watch(offerRepositoryProvider),
        expenses: ref.watch(expenseRepositoryProvider),
        categories: ref.watch(categoryRepositoryProvider),
        locations: ref.watch(locationRepositoryProvider),
        sources: ref.watch(sourceRepositoryProvider),
        purchases: ref.watch(purchaseRepositoryProvider),
      ),
    );
