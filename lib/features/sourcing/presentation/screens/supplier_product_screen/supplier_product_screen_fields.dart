part of 'supplier_product_screen.dart';

/// The text boxes of the form, and how they turn into a [SupplierProduct].
class _ProductFields {
  final TextEditingController title = TextEditingController();
  final TextEditingController url = TextEditingController();
  final TextEditingController productId = TextEditingController();
  final TextEditingController variantId = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController shipping = TextEditingController();
  final TextEditingController tax = TextEditingController();
  final TextEditingController shippingDays = TextEditingController();
  final TextEditingController stock = TextEditingController();

  void seed(SupplierProduct product) {
    title.text = product.title;
    url.text = product.url ?? '';
    productId.text = product.externalProductId ?? '';
    variantId.text = product.externalVariantId ?? '';
    price.text = product.supplierPrice?.toInputString() ?? '';
    shipping.text = product.supplierShipping?.toInputString() ?? '';
    tax.text = product.supplierTax?.toInputString() ?? '';
    shippingDays.text = product.shippingDays?.toString() ?? '';
    stock.text = product.stock?.toString() ?? '';
  }

  /// The product the boxes describe, keeping what the form does not show —
  /// the item it stocks, its rank, when it was last checked.
  SupplierProduct toProduct(
    String id,
    String sourceId,
    SupplierProduct? existing,
    String currency,
  ) => SupplierProduct(
    id: id,
    sourceId: sourceId,
    title: title.text.trim(),
    createdAt: existing?.createdAt ?? DateTime.now(),
    itemId: existing?.itemId,
    rank: existing?.rank ?? 1,
    url: TextInputUtils.orNull(url.text),
    externalProductId: TextInputUtils.orNull(productId.text),
    externalVariantId: TextInputUtils.orNull(variantId.text),
    supplierPrice: Money.tryParse(price.text, currency),
    supplierShipping: Money.tryParse(shipping.text, currency),
    supplierTax: Money.tryParse(tax.text, currency),
    shippingDays: int.tryParse(shippingDays.text.trim()),
    stock: int.tryParse(stock.text.trim()),
    lastCheckedAt: existing?.lastCheckedAt,
  );

  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      title,
      url,
      productId,
      variantId,
      price,
      shipping,
      tax,
      shippingDays,
      stock,
    ]) {
      controller.dispose();
    }
  }
}

class _FieldsForm extends StatelessWidget {
  const _FieldsForm({
    required this.fields,
    required this.currency,
    required this.onChanged,
  });

  final _ProductFields fields;
  final String currency;
  final VoidCallback onChanged;

  void _cleanTitle() {
    fields.title.text = SupplierTextCleaner.cleanTitle(fields.title.text);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final Widget gap = SizedBox(height: SdContentPaddingV3.listItemGap);
    const TextInputType wholeNumber = TextInputType.number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdTextFieldV3(
          label: context.l10n.supplierProductTitleLabel,
          controller: fields.title,
          isRequired: true,
          onChanged: (String _) => onChanged(),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SdButtonV3(
            variant: SdButtonVariantV3.text,
            label: context.l10n.supplierProductCleanTitle,
            icon: AppIconConstant.bolt,
            size: SdButtonSizeV3.small,
            onPressed: fields.title.text.trim().isEmpty ? null : _cleanTitle,
          ),
        ),
        MoneyField(
          label: context.l10n.supplierProductPriceLabel,
          controller: fields.price,
          currency: currency,
          onChanged: (String _) => onChanged(),
        ),
        gap,
        MoneyField(
          label: context.l10n.supplierProductShippingLabel,
          controller: fields.shipping,
          currency: currency,
          onChanged: (String _) => onChanged(),
        ),
        gap,
        MoneyField(
          label: context.l10n.supplierProductTaxLabel,
          controller: fields.tax,
          currency: currency,
          onChanged: (String _) => onChanged(),
        ),
        gap,
        SdTextFieldV3(
          label: context.l10n.supplierProductShippingDaysLabel,
          controller: fields.shippingDays,
          keyboardType: wholeNumber,
        ),
        gap,
        SdTextFieldV3(
          label: context.l10n.supplierProductStockLabel,
          controller: fields.stock,
          keyboardType: wholeNumber,
        ),
        gap,
        SdTextFieldV3(
          label: context.l10n.supplierProductUrlLabel,
          controller: fields.url,
          keyboardType: TextInputType.url,
        ),
        gap,
        SdTextFieldV3(
          label: context.l10n.supplierProductIdLabel,
          controller: fields.productId,
        ),
        gap,
        SdTextFieldV3(
          label: context.l10n.supplierProductVariantLabel,
          controller: fields.variantId,
        ),
      ],
    );
  }
}
