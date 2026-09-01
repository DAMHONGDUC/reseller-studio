import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_tag_hue.dart';

/// The colour a marketplace is tagged with, as the whole palette laid out.
///
/// **Tags rather than a row that opens a sheet.** Eight values that are the
/// answer to one question, and the choices *are* the information here — a
/// picker would hide them behind two taps (`SdTagV3`).
///
/// Every tag spells its colour out. Colour is never the only signal, and a
/// grid of unlabelled swatches is exactly that.
class MarketplaceHueField extends StatelessWidget {
  const MarketplaceHueField({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.helperText,
    super.key,
  });

  final String label;
  final AppTagHue selected;
  final ValueChanged<AppTagHue> onSelected;
  final String? helperText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SdFieldLabelV3(label: label),
      SizedBox(height: SdSpacingConstant.h6),
      Wrap(
        spacing: SdSpacingConstant.w8,
        runSpacing: SdSpacingConstant.h8,
        children: <Widget>[
          for (final AppTagHue hue in AppTagHue.values)
            SdTagV3(
              label: hue.label(context),
              color: hue.of(context),
              selected: hue == selected,
              onSelected: () => onSelected(hue),
            ),
        ],
      ),
      if (helperText != null) ...<Widget>[
        SizedBox(height: SdSpacingConstant.h6),
        Text(helperText!, style: context.textTheme3.bodySmall!.faint3(context)),
      ],
    ],
  );
}
