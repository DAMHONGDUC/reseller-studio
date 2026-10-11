part of 'supplier_product_screen.dart';

/// What an order costs, when the figures were last checked, and the next
/// move: list it, or open the item it already stocks.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.product,
    required this.isBusy,
    required this.onListIt,
    required this.onOpenItem,
    required this.onChecked,
  });

  final SupplierProduct product;
  final bool isBusy;
  final VoidCallback onListIt;
  final VoidCallback onOpenItem;
  final VoidCallback onChecked;

  @override
  Widget build(BuildContext context) {
    final DateTime? checked = product.lastCheckedAt;
    final TextStyle figure = context.textTheme3.titleMedium!.tabular3.copyWith(
      color: context.sdTheme3.textPrimary,
    );

    return AppSection(
      title: context.l10n.supplierProductLandedCost,
      first: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(context.money(SupplierCost.landed(product)), style: figure),
          SizedBox(height: SdSpacingConstant.h4),
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
          SizedBox(height: SdSpacingConstant.h12),
          if (product.itemId == null)
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.supplierProductListIt,
              size: SdButtonSizeV3.small,
              expand: true,
              onPressed: isBusy ? null : onListIt,
            )
          else
            SdButtonV3(
              variant: SdButtonVariantV3.secondary,
              label: context.l10n.supplierProductOpenItem,
              size: SdButtonSizeV3.small,
              expand: true,
              onPressed: onOpenItem,
            ),
          SizedBox(height: SdSpacingConstant.h8),
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: context.l10n.supplierProductMarkChecked,
            size: SdButtonSizeV3.small,
            expand: true,
            onPressed: isBusy ? null : onChecked,
          ),
        ],
      ),
    );
  }
}
