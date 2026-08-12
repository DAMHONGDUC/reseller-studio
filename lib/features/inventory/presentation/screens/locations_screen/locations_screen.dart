import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/name_entry_sheet.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/storage_location.dart';
import '../../../providers.dart';
import '../../controllers/catalog_controller.dart';

part 'locations_screen_row.dart';

/// Locations — "where is it?" (plan §7).
///
/// ```text
/// Warehouse
/// ├── Shelf
/// │   ├── Bin
/// │   └── Bin
/// └── Shelf
/// ```
///
/// **Rendered flat with indentation rather than as collapsible nodes.** A
/// seller has tens of these, not thousands, and a tree that has to be expanded
/// before it can be read costs a tap per level to answer a one-word question.
///
/// A new location's parent is asked for, not inferred: adding a bin from the
/// bottom of the list should not silently attach it to whatever happened to be
/// above it.
class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final List<StorageLocation> existing =
        ref.read(locationsProvider).value ?? const <StorageLocation>[];

    final LocationKind? kind = await OptionPickerSheet.show<LocationKind>(
      context,
      title: 'What kind?',
      options: <PickerOption<LocationKind>>[
        const PickerOption<LocationKind>(
          value: LocationKind.warehouse,
          label: 'Warehouse',
          caption: 'A room, a unit, a garage',
        ),
        const PickerOption<LocationKind>(
          value: LocationKind.shelf,
          label: 'Shelf',
          caption: 'Inside a warehouse',
        ),
        const PickerOption<LocationKind>(
          value: LocationKind.bin,
          label: 'Bin',
          caption: 'Inside a shelf — where items actually sit',
        ),
      ],
    );

    if (kind == null || !context.mounted) return;

    String? parentId;

    if (kind != LocationKind.warehouse) {
      // Only levels that can hold something are offered as a parent: a bin
      // inside a bin is not a place.
      final List<StorageLocation> parents = existing
          .where((StorageLocation location) => location.kind.canHaveChildren)
          .toList();

      if (parents.isEmpty) {
        SdSnackBarUtilsV3.info(context, 'Add a warehouse first');

        return;
      }

      final Map<String, String> paths = ref.read(locationPathsProvider);

      parentId = await OptionPickerSheet.show<String>(
        context,
        title: 'Inside which one?',
        options: parents
            .map(
              (StorageLocation parent) => PickerOption<String>(
                value: parent.id,
                label: paths[parent.id] ?? parent.name,
              ),
            )
            .toList(),
      );

      if (parentId == null || !context.mounted) return;
    }

    final String? name = await NameEntrySheet.show(
      context,
      title: 'New ${kind.name}',
      label: 'Name or code',
      hint: kind == LocationKind.bin ? 'Bin A1' : 'Garage',
    );

    if (name == null || !context.mounted) return;

    await _write(
      context,
      () => ref.read(catalogControllerProvider.notifier).saveLocation(
        name: name,
        kind: kind,
        parentId: parentId,
      ),
      'Location added',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StorageLocation location,
    int itemCount,
  ) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: 'Delete "${location.name}"?',
        message: itemCount == 0
            ? 'Nothing is stored there.'
            : '$itemCount items are there. They keep working — they just stop '
                  'having a location.',
        icon: Symbols.warning_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () => _write(
              context,
              () => ref
                  .read(catalogControllerProvider.notifier)
                  .deleteLocation(location.id),
              'Deleted',
            ),
          ),
          SdDialogActionV3(
            label: context.l10n.actionCancel,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Future<void> _write(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, done);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<StorageLocation>> source = ref.watch(
      locationsProvider,
    );
    final List<StorageLocation> locations =
        source.value ?? const <StorageLocation>[];
    final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];
    final List<StorageLocation> ordered = LocationTreeOrder.flatten(locations);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: 'Locations',
        actions: <Widget>[
          IconButton(
            icon: const SdIconV3(Symbols.add_rounded),
            tooltip: 'New location',
            onPressed: () => _add(context, ref),
          ),
        ],
      ),
      body: switch (source) {
        AsyncLoading<List<StorageLocation>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when locations.isEmpty => SdEmptyStateV3(
          icon: Symbols.shelves,
          title: 'No locations yet',
          message: 'Add a warehouse, then shelves and bins inside it.',
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'Add a location',
            onPressed: () => _add(context, ref),
          ),
        ),
        _ => ListView(
          padding: SdContentPaddingV3.screen(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: ordered
                  .map(
                    (StorageLocation location) => _LocationRow(
                      location: location,
                      itemCount: items
                          .where(
                            (Item item) => item.locationId == location.id,
                          )
                          .length,
                      onDelete: (int count) =>
                          _confirmDelete(context, ref, location, count),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      },
    );
  }
}

/// Puts a flat list of locations into reading order: each warehouse, then its
/// shelves, then each shelf's bins.
///
/// Its own class rather than a closure in `build`: it is tree arithmetic, and
/// a widget's job is layout.
final class LocationTreeOrder {
  static List<StorageLocation> flatten(List<StorageLocation> locations) {
    final List<StorageLocation> ordered = <StorageLocation>[];

    void addChildren(String? parentId) {
      final List<StorageLocation> children =
          locations
              .where((StorageLocation location) =>
                  location.parentId == parentId)
              .toList()
            ..sort(
              (StorageLocation a, StorageLocation b) =>
                  a.name.compareTo(b.name),
            );

      for (final StorageLocation child in children) {
        ordered.add(child);
        addChildren(child.id);
      }
    }

    addChildren(null);

    // Anything whose parent was deleted would otherwise vanish from the
    // screen while still holding items. Appended rather than dropped.
    for (final StorageLocation location in locations) {
      if (!ordered.contains(location)) ordered.add(location);
    }

    return ordered;
  }
}
