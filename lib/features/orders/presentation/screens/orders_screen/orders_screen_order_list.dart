part of 'orders_screen.dart';

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(clockProvider).now();

    return SliverPadding(
      padding: SdContentPaddingV3.screen(context, floatingNav: true),
      sliver: SliverList.separated(
        itemCount: orders.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(height: SdContentPaddingV3.listItemGap),
        itemBuilder: (BuildContext context, int index) => _OrderCard(
          order: orders[index],
          now: now,
          onTap: () => context.push(AppRoutes.order(orders[index].id)),
        ),
      ),
    );
  }
}
