part of 'orders_screen.dart';

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return ListView.separated(
      padding: SdContentPaddingV3.screen(context, floatingNav: true),
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: SdContentPaddingV3.listItemGap),
      itemBuilder: (BuildContext context, int index) =>
          _OrderCard(order: orders[index], now: now),
    );
  }
}
