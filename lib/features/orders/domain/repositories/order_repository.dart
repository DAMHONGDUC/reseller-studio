import '../../../inventory/domain/entities/item.dart';
import '../entities/order.dart';

/// Reading and writing orders. See `ItemRepository` for why these are
/// streams and why failures never cross this line as Firebase types.
abstract interface class OrderRepository {
  /// Every order, newest first. The Orders screen's five tabs are a fold over
  /// this one stream rather than five queries.
  Stream<List<Order>> watchOrders();

  Stream<Order?> watchOrder(String id);

  Future<Order?> findById(String id);

  Future<void> save(Order order);

  /// Writes the order and decrements its inventory item as one commit.
  Future<void> recordSale(Order order, Item item);

  /// Writes the returned order and restores line quantities as one commit.
  Future<void> closeReturn(Order order, {required bool restock});
}
