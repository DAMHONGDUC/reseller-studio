part of 'receipts_screen.dart';

/// The document, large enough to read.
///
/// **Zoomable**, because the whole point of keeping a receipt is being able to
/// read its small print a year later — a fixed-size image of a paper receipt
/// is a picture of some numbers, not a record.
class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.receipt});

  final ReceiptEntry receipt;

  /// How far in the seller can pinch. Four is enough to read a line item on a
  /// photographed till roll without the image falling apart.
  static const double maxZoom = 4;

  static Future<void> show(BuildContext context, ReceiptEntry receipt) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => _ReceiptPreview(receipt: receipt),
      );

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: receipt.title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: SdSpacingConstant.h200 * 2),
          child: InteractiveViewer(
            maxScale: maxZoom,
            child: AppPhoto(
              url: receipt.url,
              size: SdSpacingConstant.h200 * 2,
              borderRadius: SdRadiusV3.cardAll,
            ),
          ),
        ),
        SizedBox(height: SdSpacingConstant.h16),
        SdButtonV3(
          variant: SdButtonVariantV3.secondary,
          label: receipt.kind == ReceiptKind.purchase
              ? 'Open the purchase'
              : 'Open expenses',
          expand: true,
          onPressed: () {
            Navigator.of(context).pop();

            // An expense has no detail screen of its own — the list is where
            // it is edited — so the two kinds land in different places.
            context.push(
              receipt.kind == ReceiptKind.purchase
                  ? AppRoutes.purchase(receipt.recordId)
                  : AppRoutes.expenses,
            );
          },
        ),
      ],
    ),
  );
}
