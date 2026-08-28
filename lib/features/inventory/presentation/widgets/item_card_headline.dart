part of 'item_card.dart';

/// The title, and the number the list is scanned for.
///
/// **The asking price sits at the end of the title row** — the same shape the
/// order and offer cards use. A price buried in a line of figures below the
/// badges gives the eye nothing to travel down; at the card's edge it forms a
/// column a seller reads straight through a screenful of rows.
///
/// It renders `—` when nobody has set one (hard rule 5), which on a Quick Add
/// row is the most useful thing the card can say.
class _Headline extends StatelessWidget {
  const _Headline({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Text(
          item.title,
          style: context.textTheme3.bodyLarge!.semiBold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      SizedBox(width: SdSpacingConstant.w8),
      Text(
        context.money(item.askingPrice),
        style: context.textTheme3.titleSmall!.bold3.tabular3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
      ),
    ],
  );
}
