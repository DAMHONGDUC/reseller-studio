part of 'item_detail_screen.dart';

/// Where it came from and where it is — the two halves of the plan's Purchase
/// and Location blocks (§7).
///
/// **This is the chain made visible.** `Source → Purchase → Item` is what
/// makes "which source performs best" answerable, and a detail screen that
/// showed only the price would give a seller no reason to fill it in.
class _Provenance extends ConsumerWidget {
  const _Provenance({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> sources = ref.watch(sourceNamesProvider);
    final Map<String, String> categories = ref.watch(categoryNamesProvider);
    final Map<String, String> locations = ref.watch(locationPathsProvider);
    final String dash = context.l10n.emptyValuePlaceholder;

    return SdCardV3(
      child: Column(
        children: <Widget>[
          _DetailRow(
            label: context.l10n.commonSource,
            value: sources[item.sourceId] ?? dash,
          ),
          _DetailRow(
            label: context.l10n.itemPurchased,
            value: item.purchaseDate == null
                ? dash
                : DateTimeUtils.mediumDate(
                    item.purchaseDate!,
                    locale: context.localeTag,
                  ),
          ),
          _DetailRow(
            label: context.l10n.commonCategory,
            value: categories[item.categoryId] ?? dash,
          ),
          _DetailRow(
            label: context.l10n.commonLocation,
            value: locations[item.locationId] ?? dash,
          ),
          _DetailRow(
            label: context.l10n.commonBarcode,
            value: item.barcode ?? dash,
          ),
          // **Read-only, and only here** — owner's rule. Both are records of
          // when something happened, so no form offers them: a date a seller
          // can type is not a record of anything.
          _DetailRow(
            label: context.l10n.itemAdded,
            value: DateTimeUtils.mediumDate(
              item.createdAt,
              locale: context.localeTag,
            ),
          ),
          _DetailRow(
            label: context.l10n.itemLastUpdated,
            value: item.updatedAt == null
                ? dash
                : DateTimeUtils.dateTime(
                    item.updatedAt!,
                    locale: context.localeTag,
                  ),
          ),
        ],
      ),
    );
  }
}
