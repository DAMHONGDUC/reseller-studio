part of 'item_card.dart';

class _PriceCell extends StatelessWidget {
  const _PriceCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        label,
        style: context.textTheme3.bodySmall!.faint3(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        value,
        style: context.textTheme3.bodyMedium!.semiBold3.tabular3.copyWith(
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
