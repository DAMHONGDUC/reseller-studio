import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../listings/domain/entities/title_parts.dart';
import '../../../listings/domain/services/title_builder.dart';
import '../../../marketplaces/domain/entities/marketplace.dart';
import '../../../marketplaces/providers.dart';

/// Builds a title from its parts, inside a marketplace's limit
/// (`docs/DROPSHIPPING_PLAN.md`, decision 11.9 — rules, not a model).
///
/// Returns the title, or null when the sheet is closed; the caller puts it
/// in its own field, so nothing is saved until the seller saves the section.
class TitleBuilderSheet extends ConsumerStatefulWidget {
  const TitleBuilderSheet({required this.condition, super.key});

  /// The item's grade as it reads, offered as the last part.
  final String? condition;

  static Future<String?> show(BuildContext context, {String? condition}) =>
      showSdBottomSheetV3<String>(
        context: context,
        builder: (BuildContext context) =>
            TitleBuilderSheet(condition: condition),
      );

  @override
  ConsumerState<TitleBuilderSheet> createState() => _TitleBuilderSheetState();
}

class _TitleBuilderSheetState extends ConsumerState<TitleBuilderSheet> {
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _type = TextEditingController();
  final TextEditingController _attributes = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _size = TextEditingController();
  String _marketplaceId = 'ebay';

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _brand,
      _type,
      _attributes,
      _color,
      _size,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _title() => TitleBuilder.build(
    TitleParts(
      brand: _brand.text,
      productType: _type.text,
      attributes: _attributes.text
          .split(',')
          .map((String part) => part.trim())
          .where((String part) => part.isNotEmpty)
          .toList(),
      color: _color.text,
      size: _size.text,
      condition: widget.condition,
    ),
    maxLength: TitleBuilder.maxLengthFor(_marketplaceId),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: EdgeInsets.only(bottom: SdSpacingConstant.h12),
    child: SdTextFieldV3(
      label: label,
      controller: controller,
      textInputAction: TextInputAction.next,
      onChanged: (String _) => setState(() {}),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<Marketplace> marketplaces = ref.watch(
      activeMarketplacesProvider,
    );
    final String title = _title();
    final int limit = TitleBuilder.maxLengthFor(_marketplaceId);

    return SdBottomSheetV3(
      title: context.l10n.titleBuilderTitle,
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _field(_brand, context.l10n.titleBuilderBrand),
          _field(_type, context.l10n.titleBuilderType),
          _field(_attributes, context.l10n.titleBuilderAttributes),
          _field(_color, context.l10n.titleBuilderColor),
          _field(_size, context.l10n.titleBuilderSize),
          SdFieldLabelV3(label: context.l10n.titleBuilderFor),
          SizedBox(height: SdSpacingConstant.h6),
          Wrap(
            spacing: SdSpacingConstant.w8,
            runSpacing: SdSpacingConstant.h8,
            children: <Widget>[
              for (final Marketplace marketplace in marketplaces)
                SdTagV3(
                  label: marketplace.name,
                  color: marketplace.hue.of(context),
                  selected: marketplace.id == _marketplaceId,
                  onSelected: () =>
                      setState(() => _marketplaceId = marketplace.id),
                ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdCardV3(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: SdMotionV3.fast,
                  child: Text(
                    title.isEmpty ? '—' : title,
                    key: ValueKey<String>(title),
                    style: context.textTheme3.bodyMedium!.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: SdSpacingConstant.h4),
                Text(
                  context.l10n.titleBuilderLength(title.length, limit),
                  style: context.textTheme3.bodySmall!.muted3(context),
                ),
              ],
            ),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.titleBuilderUse,
            expand: true,
            onPressed: title.isEmpty
                ? null
                : () => Navigator.of(context).pop(title),
          ),
        ],
      ),
    );
  }
}
