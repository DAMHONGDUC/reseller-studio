import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/carrier.dart';
import '../../domain/repositories/carrier_repository.dart';
import '../dtos/carrier_dto.dart';

/// The carriers a guest ships with (`docs/rules/GUEST_MODE.md`).
class LocalCarrierRepository implements CarrierRepository {
  LocalCarrierRepository(LocalDatabase db)
    : _collection = LocalCollection<Carrier>(
        table: LocalTable(db, db.localCarriers),
        fromMap: CarrierDto.fromMap,
        toMap: (Carrier carrier) =>
            CarrierDto.toMap(carrier, createdBy: GuestConstant.uid),
        idOf: (Carrier carrier) => carrier.id,
        createdAtOf: (Carrier carrier) => carrier.createdAt,
        isDeleted: (Carrier carrier) => carrier.isDeleted,
        logTag: LogTagConstant.carrier,
        label: 'carrier',
      );

  final LocalCollection<Carrier> _collection;

  @override
  Stream<List<Carrier>> watchCarriers() => _collection.watchAll();

  @override
  Future<void> save(Carrier carrier) => _collection.save(carrier);

  @override
  Future<void> saveAll(List<Carrier> carriers) => _collection.saveAll(carriers);

  @override
  Future<void> delete(String carrierId) => _collection.softDelete(carrierId);
}
