part of 'inventory_screen.dart';

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    // One `now` for the whole list, so every row agrees on what stale means.
    final DateTime now = DateTime.now();

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        0,
        SdContentPaddingV3.horizontal,
        // Clears the floating tab bar AND the FAB stacked above it —
        // otherwise the last row sits under "Quick Add" and cannot be tapped.
        SdContentPaddingV3.bottom(context, floatingNav: true) + SdFabV3.size,
      ),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(height: SdContentPaddingV3.listItemGap),
        itemBuilder: (BuildContext context, int index) {
          final Item item = items[index];

          return ItemCard(
            item: item,
            now: now,
            onTap: () => context.push(AppRoutes.item(item.id)),
          );
        },
      ),
    );
  }
}
