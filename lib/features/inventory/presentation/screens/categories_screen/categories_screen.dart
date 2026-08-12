import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/name_entry_sheet.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/item_category.dart';
import '../../../providers.dart';
import '../../controllers/catalog_controller.dart';

/// Categories — what kind of thing each item is (plan §10).
///
/// **Each row carries its item count**, because the only question a seller
/// asks on this screen is which categories are actually earning their keep,
/// and a list of bare names cannot answer it.
///
/// Deleting is a soft delete (hard rule 15): items point at these, and a hard
/// delete would leave them categorised as nothing with no way to tell that
/// from never having been categorised.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final String? name = await NameEntrySheet.show(
      context,
      title: 'New category',
      label: 'Name',
      hint: 'Outerwear',
    );

    if (name == null || !context.mounted) return;

    await _write(
      context,
      () => ref.read(catalogControllerProvider.notifier).saveCategory(
        name: name,
      ),
      'Category added',
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ItemCategory category,
  ) async {
    final String? name = await NameEntrySheet.show(
      context,
      title: 'Rename category',
      label: 'Name',
      initialValue: category.name,
    );

    if (name == null || !context.mounted) return;

    await _write(
      context,
      () => ref.read(catalogControllerProvider.notifier).saveCategory(
        name: name,
        id: category.id,
        parentId: category.parentId,
      ),
      'Renamed',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ItemCategory category,
    int itemCount,
  ) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: 'Delete "${category.name}"?',
        message: itemCount == 0
            ? 'Nothing is using it.'
            : '$itemCount items are in it. They keep working — they just stop '
                  'having a category.',
        icon: Symbols.warning_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () => _write(
              context,
              () => ref
                  .read(catalogControllerProvider.notifier)
                  .deleteCategory(category.id),
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

  /// The one place a write's outcome becomes a message.
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
    final AsyncValue<List<ItemCategory>> source = ref.watch(
      categoriesProvider,
    );
    final List<ItemCategory> categories =
        source.value ?? const <ItemCategory>[];
    final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];

    return AppAddFabScaffold(
      appBar: const SdAppBarV3(title: 'Categories'),
      addLabel: 'Add a category',
      onAdd: () => _add(context, ref),
      body: switch (source) {
        AsyncLoading<List<ItemCategory>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when categories.isEmpty => SdEmptyStateV3(
          icon: Symbols.category_rounded,
          title: 'No categories yet',
          message: 'Group your stock so analytics can tell you what sells.',
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'Add a category',
            onPressed: () => _add(context, ref),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: categories.map((ItemCategory category) {
                final int count = items
                    .where((Item item) => item.categoryId == category.id)
                    .length;

                return AppListRow(
                  title: category.name,
                  subtitle: count == 1 ? '1 item' : '$count items',
                  icon: Symbols.category_rounded,
                  onTap: () => _rename(context, ref, category),
                  trailing: IconButton(
                    icon: SdIconV3(
                      Symbols.delete_rounded,
                      size: SdIconV3.smallSize,
                      color: context.sdTheme3.textTertiary,
                    ),
                    tooltip: context.l10n.actionDelete,
                    onPressed: () =>
                        _confirmDelete(context, ref, category, count),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      },
    );
  }
}
