part of 'orders_screen.dart';

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders});

  /// The one ceiling this screen's records count against.
  static const List<PlanAllowance> _meterAllowances = <PlanAllowance>[
    PlanAllowance.orders,
  ];

  final List<Order> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(clockProvider).now();
    // The meter is item zero rather than a widget above the list: the gap
    // between the filter strip and the list has one owner and one value
    // (`docs/rules/DESIGN_SYSTEM.md`), so nothing may sit in it.
    final int header =
        PlanLimitMeters.cappedIn(ref, allowances: _meterAllowances).isEmpty
        ? 0
        : 1;

    return ListView.separated(
      // Clears the create button as well as the glass bar; without it the
      // last order sits under the button and cannot be tapped.
      padding: AppAddFabScaffold.listPadding(context, floatingNav: true),
      itemCount: orders.length + header,
      // The separator between the meter and the first card is the same gap
      // as between two cards, and it belongs to neither of them.
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: SdContentPaddingV3.listItemGap),
      itemBuilder: (BuildContext context, int index) {
        if (index < header) {
          return const PlanLimitMeters(allowances: _meterAllowances);
        }

        final Order order = orders[index - header];

        return _OrderCard(
          order: order,
          now: now,
          onTap: () => context.push(AppRoutes.order(order.id)),
        );
      },
    );
  }
}
