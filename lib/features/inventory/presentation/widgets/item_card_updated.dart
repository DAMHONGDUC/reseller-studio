part of 'item_card.dart';

/// When the record last changed.
///
/// **The last line, and the quietest** — owner's rule that it show on the
/// row. It answers "did my edit save?" and "which of these did I touch this
/// morning?", which is a different question from every figure above it and
/// deserves none of their weight.
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
      padding: EdgeInsets.only(top: SdSpacingConstant.h8),
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
