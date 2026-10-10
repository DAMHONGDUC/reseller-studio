part of 'scan_result_screen.dart';

/// A bin label: where it is, and what is on it now — the question a seller
/// scanning a shelf is asking.
class _LocationResult extends ConsumerWidget {
  const _LocationResult({required this.match});

  final ScanMatchLocation match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String path =
        ref.watch(locationPathsProvider)[match.location.id] ??
        match.location.name;

    if (match.items.isEmpty) {
      return AppSection(
        title: context.l10n.scanResultItemsHere,
        subtitle: path,
        child: Text(
          context.l10n.scanResultNothingHere,
          style: context.textTheme3.bodyMedium!.muted3(context),
        ),
      );
    }

    return AppSection.rows(
      title: context.l10n.scanResultItemsHere,
      subtitle: path,
      children: <Widget>[
        for (final Item item in match.items)
          AppListRow(
            title: item.title,
            subtitle: item.sku,
            onTap: () => context.push(AppRoutes.item(item.id)),
          ),
      ],
    );
  }
}
