import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/marketplace.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../dtos/marketplace_dto.dart';

/// The platforms a guest sells on (`docs/rules/GUEST_MODE.md`).
class LocalMarketplaceRepository implements MarketplaceRepository {
  LocalMarketplaceRepository(LocalDatabase db)
    : _collection = LocalCollection<Marketplace>(
        table: LocalTable(db, db.localMarketplaces),
        fromMap: MarketplaceDto.fromMap,
        toMap: (Marketplace marketplace) =>
            MarketplaceDto.toMap(marketplace, createdBy: GuestConstant.uid),
        idOf: (Marketplace marketplace) => marketplace.id,
        createdAtOf: (Marketplace marketplace) => marketplace.createdAt,
        isDeleted: (Marketplace marketplace) => marketplace.isDeleted,
        logTag: LogTagConstant.marketplace,
        label: 'marketplace',
      );

  final LocalCollection<Marketplace> _collection;

  @override
  Stream<List<Marketplace>> watchMarketplaces() => _collection.watchAll();

  @override
  Future<void> save(Marketplace marketplace) => _collection.save(marketplace);

  @override
  Future<void> saveAll(List<Marketplace> marketplaces) =>
      _collection.saveAll(marketplaces);

  @override
  Future<void> delete(String marketplaceId) =>
      _collection.softDelete(marketplaceId);
}
