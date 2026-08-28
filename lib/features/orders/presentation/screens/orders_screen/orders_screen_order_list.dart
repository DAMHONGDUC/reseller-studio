part of 'orders_screen.dart';

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(clockProvider).now();

    return ListView.separated(
      // Clears the create button as well as the glass bar; without it the
      // last order sits under the button and cannot be tapped.
      padding: AppAddFabScaffold.listPadding(context, floatingNav: true),
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: SdContentPaddingV3.listItemGap),
      itemBuilder: (BuildContext context, int index) => _OrderCard(
        order: orders[index],
        now: now,
        onTap: () => context.push(AppRoutes.order(orders[index].id)),
      ),
    );
  }
}
