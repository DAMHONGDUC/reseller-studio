part of 'item_card.dart';

/// When the record last changed, and anything the row is flagging.
///
/// **It closes the identity column, never the money band** — owner's rule.
/// It answers "did my edit save?" and "which of these did I touch this
/// morning?", which is a fact about the record rather than about what the item
/// is worth; hung under Qty and Cost it read as a fourth row of that grid.
///
/// The quietest thing in its zone, and it deserves none of the weight the
/// figures below it carry.
///
/// The date is absent when nothing has ever updated the record, rather than
/// dressing the creation date up as an edit.
///
/// **The warning is a tag beside it** — owner's rule. The badges above say
/// what the item *is*; a contradiction is something about the record, which is
/// the question this line already answers. It is short on purpose: the
/// sentence that explains it belongs to the detail screen, which has the width
/// for one.
class _UpdatedLine extends StatelessWidget {
  const _UpdatedLine({
    required this.item,
    required this.warnings,
    required this.notice,
  });

  final Item item;

  /// What the record says that cannot all be true at once.
  final List<ItemWarning> warnings;

  /// A short flag from the screen rather than from the record — the sale
  /// picker's reason. Drawn only when [warnings] is empty, so one row never
  /// states the same problem twice.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final DateTime? updated = item.updatedAt;
    final bool isFlagged = warnings.isNotEmpty || notice != null;

    if (updated == null && !isFlagged) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: ItemCardMetricConstant.updatedGap),
      child: Wrap(
        spacing: ItemCardMetricConstant.tagGap,
        runSpacing: ItemCardMetricConstant.tagRunGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (updated != null)
            Text(
              context.l10n.itemUpdatedAt(
                DateTimeUtils.shortDate(updated, locale: context.localeTag),
              ),
              style: context.textTheme3.bodySmall!.faint3(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          for (final ItemWarning warning in warnings)
            _DisplayTag(
              label: warning.label(context),
              color: warning.color(context),
              icon: AppIconConstant.warning,
            ),
          if (warnings.isEmpty && notice != null)
            _DisplayTag(
              label: notice!,
              color: context.sdTheme3.warning,
              icon: AppIconConstant.warning,
            ),
        ],
      ),
    );
  }
}
