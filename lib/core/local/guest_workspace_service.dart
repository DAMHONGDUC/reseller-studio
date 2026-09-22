import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:system_design/common.dart';

import '../../features/carriers/data/repositories/local_carrier_repository.dart';
import '../../features/carriers/domain/entities/carrier.dart';
import '../../features/inventory/data/repositories/local_catalog_repositories.dart';
import '../../features/inventory/domain/entities/item_category.dart';
import '../../features/marketplaces/data/repositories/local_marketplace_repository.dart';
import '../../features/marketplaces/domain/entities/marketplace.dart';
import '../../features/pricing/domain/services/profit_calculator.dart';
import '../../features/workspace/data/dtos/workspace_dto.dart';
import '../../features/workspace/domain/entities/workspace.dart';
import '../constants/guest_constant.dart';
import '../constants/log_tag_constant.dart';
import '../utils/locale_default_utils.dart';
import 'local_database.dart';
import 'local_table.dart';

/// Creates the business a guest starts with, once.
///
/// **Nobody is asked anything** — hard rule 2 taken to its end: a seller who
/// opens the app for the first time is put in front of Quick Add, not a form
/// about their country. Country and currency are guessed from the device
/// locale (`LocaleDefaultUtils`) and corrected in Settings, which is the one
/// place a wrong guess costs a tap rather than a record.
///
/// **Idempotent.** It reads the workspace row first and returns if it is
/// there, so a cold start after a crash mid-seed does not double the
/// defaults.
class GuestWorkspaceService {
  const GuestWorkspaceService(this._db);

  final LocalDatabase _db;

  Future<void> ensureExists({
    required List<Marketplace> marketplaces,
    required List<ItemCategory> categories,
    required List<Carrier> carriers,
  }) async {
    final LocalTable workspaces = LocalTable(_db, _db.localWorkspaces);

    if (await workspaces.findById(GuestConstant.workspaceId) != null) return;

    final String locale = LocaleDefaultUtils.deviceLocale;
    final DateTime now = DateTime.now();
    final Workspace workspace = Workspace(
      id: GuestConstant.workspaceId,
      name: GuestConstant.workspaceName,
      ownerId: GuestConstant.uid,
      country: LocaleDefaultUtils.countryFor(locale),
      currency: LocaleDefaultUtils.currencyFor(locale),
      createdAt: now,
    );

    // The DTO owns every field a workspace can be edited on; what is added
    // here is exactly what `createWorkspace` adds on the Firestore side —
    // ownership and the instant it came into being.
    await workspaces.put(GuestConstant.workspaceId, now, <String, Object?>{
      ...WorkspaceDto.toUpdateMap(workspace),
      'ownerId': GuestConstant.uid,
      'createdBy': GuestConstant.uid,
      'createdAt': Timestamp.fromDate(now),
      'staleThresholdDays': StaleInventoryPolicy.defaultThresholdDays,
    });

    // Written through the guest repositories, not around them — the same
    // reason `SeedDataSeeder` drives the real write paths.
    await LocalMarketplaceRepository(_db).saveAll(marketplaces);
    await LocalCarrierRepository(_db).saveAll(carriers);

    for (final ItemCategory category in categories) {
      await LocalCategoryRepository(_db).save(category);
    }

    SdLogger.action(
      LogTagConstant.workspace,
      'Guest business created',
      <String, Object>{
        'country': workspace.country,
        'currency': workspace.currency,
        'marketplaces': marketplaces.length,
        'categories': categories.length,
        'carriers': carriers.length,
      },
    );
  }
}
