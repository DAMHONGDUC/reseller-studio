import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import 'app_photo.dart';

/// The receipt slot on a purchase or expense form.
///
/// Camera first, library second: the paper is usually in the seller's hand,
/// and the photo they want does not exist yet.
///
/// In `core/widgets/` because two features draw it and the second copy is the
/// trigger. It knows nothing about uploading — the caller's controller does
/// that and hands back a URL, which keeps this a layout.
class ReceiptField extends StatelessWidget {
  const ReceiptField({
    required this.url,
    required this.isBusy,
    required this.onCamera,
    required this.onLibrary,
    required this.onRemove,
    super.key,
  });

  /// Null when nothing is attached yet.
  final String? url;

  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onLibrary;
  final VoidCallback onRemove;

  static double get thumbnailSize => SdSpacingConstant.r64;

  @override
  Widget build(BuildContext context) {
    final String? attached = url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Receipt',
          style: context.textTheme3.labelMedium!.muted3(context),
        ),
        SizedBox(height: SdSpacingConstant.h6),
        if (attached != null)
          Row(
            children: <Widget>[
              AppPhoto(url: attached, size: thumbnailSize),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Text(
                  'Attached',
                  style: context.textTheme3.bodyMedium!.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: SdIconV3(
                  Symbols.close_rounded,
                  size: SdIconV3.smallSize,
                  color: context.sdTheme3.danger,
                ),
                tooltip: 'Remove receipt',
                onPressed: onRemove,
              ),
            ],
          )
        else
          Row(
            children: <Widget>[
              Expanded(
                child: SdButtonV3(
                  variant: SdButtonVariantV3.outlined,
                  label: 'Photograph',
                  icon: Symbols.photo_camera_rounded,
                  size: SdButtonSizeV3.small,
                  expand: true,
                  busy: isBusy,
                  onPressed: isBusy ? null : onCamera,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdButtonV3(
                  variant: SdButtonVariantV3.outlined,
                  label: 'Choose',
                  icon: Symbols.photo_library_rounded,
                  size: SdButtonSizeV3.small,
                  expand: true,
                  busy: isBusy,
                  onPressed: isBusy ? null : onLibrary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
