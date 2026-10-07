part of 'scan_result_screen.dart';

/// The code as the camera read it, and what it turned out to be — so a
/// misread is visible before the seller acts on it.
class _ScannedCode extends StatelessWidget {
  const _ScannedCode({required this.match});

  final ScanMatch match;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color tint, String verdict) = switch (match) {
      ScanMatchItem() => (
        AppIconConstant.inventory,
        context.sdTheme3.success,
        context.l10n.scanResultFoundItem,
      ),
      ScanMatchLocation() => (
        AppIconConstant.shelves,
        context.sdTheme3.info,
        context.l10n.scanResultFoundLocation,
      ),
      ScanMatchNone() => (
        AppIconConstant.qrCodeScanner,
        context.sdTheme3.warning,
        context.l10n.scannerNoMatchTitle,
      ),
    };

    return SdCardV3(
      padding: SdContentPaddingV3.row,
      child: Row(
        children: <Widget>[
          SdIconTileV3(icon: icon, tint: tint),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.l10n.scanResultCodeLabel,
                  style: context.textTheme3.labelMedium!.muted3(context),
                ),
                SizedBox(height: SdSpacingConstant.h2),
                Text(
                  match.code,
                  style: context.textTheme3.titleMedium!.semiBold3.tabular3
                      .copyWith(color: context.sdTheme3.textPrimary),
                ),
                SizedBox(height: SdSpacingConstant.h2),
                Text(
                  verdict,
                  style: context.textTheme3.bodySmall!.copyWith(color: tint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
