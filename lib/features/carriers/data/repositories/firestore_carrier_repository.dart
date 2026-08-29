import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/carrier.dart';
import '../../domain/repositories/carrier_repository.dart';
import '../dtos/carrier_dto.dart';

class FirestoreCarrierRepository implements CarrierRepository {
  const FirestoreCarrierRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Carrier>> watchCarriers() => FirestoreStream.collection(
    _context.collections.carriers.orderBy('createdAt'),
    CarrierDto.toEntity,
    operation: 'load carriers',
  );

  @override
  Future<void> save(Carrier carrier) =>
      FailureMapper.guard('save carrier', () async {
        await _context.collections.carriers
            .doc(carrier.id)
            .set(
              CarrierDto.toMap(carrier, createdBy: _context.uid),
              SetOptions(merge: true),
            );
        SdLogger.info(LogTagConstant.order, 'Carrier saved', <String, Object>{
          'carrierId': carrier.id,
        });
      });

  @override
  Future<void> saveAll(List<Carrier> carriers) => FailureMapper.guard(
    'seed carriers',
    () async {
      if (carriers.isEmpty) return;

      final WriteBatch batch = _context.collections.carriers.firestore.batch();
      for (final Carrier carrier in carriers) {
        batch.set(
          _context.collections.carriers.doc(carrier.id),
          CarrierDto.toMap(carrier, createdBy: _context.uid),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      SdLogger.info(LogTagConstant.order, 'Carriers seeded', <String, Object>{
        'count': carriers.length,
      });
    },
  );

  @override
  Future<void> delete(String carrierId) => FailureMapper.guard(
    'delete carrier',
    () async {
      await _context.collections.carriers.doc(carrierId).set(<String, Object?>{
        'deletedAt': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      SdLogger.info(LogTagConstant.order, 'Carrier deleted', <String, Object>{
        'carrierId': carrierId,
      });
    },
  );
}
