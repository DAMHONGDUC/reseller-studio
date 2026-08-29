import '../entities/carrier.dart';

abstract interface class CarrierRepository {
  Stream<List<Carrier>> watchCarriers();

  Future<void> save(Carrier carrier);

  Future<void> saveAll(List<Carrier> carriers);

  Future<void> delete(String carrierId);
}
