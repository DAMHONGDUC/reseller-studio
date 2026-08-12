part of 'order_detail_screen.dart';

/// What was on the order.
///
/// Each row links back to the item, which is what makes the chain walkable in
/// both directions: from a sale to the thing sold, and from the thing sold to
/// the source it came from.
///
/// **The prices here are what the buyer paid**, copied at sale time and never
/// refreshed — repricing the item afterwards must not rewrite history.
class _OrderLines extends StatelessWidget {
  const _OrderLines({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => AppListCard(
    children: order.lines
        .map(
          (OrderLine line) => AppListRow(
            title: line.title,
            subtitle: line.quantity == 1
                ? 'Cost ${context.money(line.unitCost)}'
                : '×${line.quantity} · cost ${context.money(line.unitCost)}',
            trailingText: context.money(line.lineTotal),
            onTap: () => context.push(AppRoutes.item(line.itemId)),
          ),
        )
        .toList(),
  );
}
