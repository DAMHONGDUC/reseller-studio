part of 'item_card.dart';

/// When the record last changed.
///
/// **It closes the identity column, never the money band** — owner's rule.
/// It answers "did my edit save?" and "which of these did I touch this
/// morning?", which is a fact about the record rather than about what the item
/// is worth; hung under Qty and Cost it read as a fourth row of that grid.
///
/// The quietest thing in its zone, and it deserves none of the weight the
/// figures below it carry.
///
/// Absent when nothing has ever updated the record, rather than dressing the
/// creation date up as an edit.
class _UpdatedLine extends StatelessWidget {
  const _UpdatedLine({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final DateTime? updated = item.updatedAt;

    if (updated == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: ItemCardMetricConstant.updatedGap),
      child: Text(
        context.l10n.itemUpdatedAt(
          DateTimeUtils.shortDate(updated, locale: context.localeTag),
        ),
        style: context.textTheme3.bodySmall!.faint3(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
