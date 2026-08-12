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
            label: 'Source',
            value: sources[item.sourceId] ?? dash,
          ),
          _DetailRow(
            label: 'Purchased',
            value: item.purchaseDate == null
                ? dash
                : DateTimeUtils.mediumDate(
                    item.purchaseDate!,
                    locale: context.localeTag,
                  ),
          ),
          _DetailRow(
            label: 'Category',
            value: categories[item.categoryId] ?? dash,
          ),
          _DetailRow(
            label: 'Location',
            value: locations[item.locationId] ?? dash,
          ),
          _DetailRow(label: 'Barcode', value: item.barcode ?? dash),
        ],
      ),
    );
  }
}
