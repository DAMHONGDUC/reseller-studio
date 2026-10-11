part of 'item_detail_screen.dart';

/// Who ships a dropshipped item, primary first, and what an order costs at
/// each (`docs/DROPSHIPPING_PLAN.md`). Absent on a stocked item.
class _SuppliersSection extends ConsumerWidget {
  const _SuppliersSection({required this.item});

  final Item item;

  Future<void> _addBackup(
    BuildContext context,
    WidgetRef ref,
    List<SupplierProduct> current,
  ) async {
    final Map<String, String> names = ref.read(sourceNamesProvider);
    final List<SupplierProduct> unlinked = <SupplierProduct>[
      for (final SupplierProduct product in ref.read(
        activeSupplierProductsProvider,
      ))
        if (product.itemId == null) product,
    ];

    if (unlinked.isEmpty) {
      SdSnackBarUtilsV3.info(context, context.l10n.supplierProductNoneUnlinked);

      return;
    }

    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.supplierProductPickTitle,
      options: <PickerOption<String>>[
        for (final SupplierProduct product in unlinked)
          PickerOption<String>(
            value: product.id,
            label: product.title,
            caption: names[product.sourceId],
          ),
      ],
    );
    final SupplierProduct? product = unlinked
        .where((SupplierProduct p) => p.id == picked)
        .firstOrNull;

    if (product == null) return;

    await ref
        .read(supplierProductControllerProvider.notifier)
        .linkBackup(item.id, product, current);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SupplierProduct> products = ref.watch(
      supplierProductsForItemProvider(item.id),
    );
    final Map<String, String> names = ref.watch(sourceNamesProvider);

    if (!item.isDropship) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: SdContentPaddingV3.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdSectionHeaderV3(
            title: context.l10n.itemSupplierSection,
            action: SdButtonV3(
              variant: SdButtonVariantV3.text,
              label: context.l10n.itemSupplierAddBackup,
              icon: AppIconConstant.add,
              size: SdButtonSizeV3.small,
              onPressed: () => _addBackup(context, ref, products),
            ),
          ),
          SdCardV3(
            child: products.isEmpty
                ? Text(
                    context.l10n.itemSupplierNone,
                    style: context.textTheme3.bodyMedium!.muted3(context),
                  )
                : Column(
                    children: <Widget>[
                      for (int i = 0; i < products.length; i++) ...<Widget>[
                        _SupplierRow(
                          product: products[i],
                          supplier: names[products[i].sourceId],
                          onMakePrimary: products[i].isPrimary
                              ? null
                              : () => ref
                                    .read(
                                      supplierProductControllerProvider
                                          .notifier,
                                    )
                                    .makePrimary(products[i], products),
                        ),
                        if (i != products.length - 1) const SdDividerV3(),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.product,
    required this.supplier,
    required this.onMakePrimary,
  });

  final SupplierProduct product;
  final String? supplier;
  final VoidCallback? onMakePrimary;

  @override
  Widget build(BuildContext context) {
    final int? stock = product.stock;
    final DateTime? checked = product.lastCheckedAt;

    return InkWell(
      onTap: () =>
          context.push(AppRoutes.supplierProduct(product.sourceId, product.id)),
      child: Padding(
        padding: SdContentPaddingV3.rowNoGutter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    supplier ?? product.title,
                    style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                ),
                Text(
                  context.money(SupplierCost.landed(product)),
                  style: context.textTheme3.bodyMedium!.tabular3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h6),
            Wrap(
              spacing: SdSpacingConstant.w8,
              runSpacing: SdSpacingConstant.h4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SdBadgeV3(
                  label: product.isPrimary
                      ? context.l10n.itemSupplierPrimary
                      : context.l10n.itemSupplierBackup,
                  tone: product.isPrimary
                      ? SdBadgeToneV3.success
                      : SdBadgeToneV3.neutral,
                ),
                if (stock != null)
                  SdBadgeV3(
                    label: context.l10n.supplierProductStockValue(stock),
                    tone: stock == 0
                        ? SdBadgeToneV3.danger
                        : SdBadgeToneV3.neutral,
                  ),
                Text(
                  checked == null
                      ? context.l10n.supplierProductNeverChecked
                      : context.l10n.supplierProductCheckedOn(
                          DateTimeUtils.mediumDate(
                            checked,
                            locale: context.localeTag,
                          ),
                        ),
                  style: context.textTheme3.bodySmall!.muted3(context),
                ),
                if (onMakePrimary != null)
                  SdButtonV3(
                    variant: SdButtonVariantV3.text,
                    label: context.l10n.itemSupplierMakePrimary,
                    size: SdButtonSizeV3.small,
                    onPressed: onMakePrimary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
