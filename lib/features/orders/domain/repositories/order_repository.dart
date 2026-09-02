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

  /// Writes the order and decrements every item it names, as one commit.
  ///
  /// **A list because an order may be a bundle.** One payment for three things
  /// is one order, and three separate commits is a state where two items are
  /// sold, the screen showed an error, and nobody can tell which two.
  Future<void> recordSale(Order order, List<Item> items);

  /// Writes the returned order and restores line quantities as one commit.
  Future<void> closeReturn(Order order, {required bool restock});
}
