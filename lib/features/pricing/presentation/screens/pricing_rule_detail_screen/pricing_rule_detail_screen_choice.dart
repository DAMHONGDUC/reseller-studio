part of 'pricing_rule_detail_screen.dart';

/// One question answered by a row of tags — the whole vocabulary laid out,
/// the way the item form asks for status and condition.
class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.colorOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final Color Function(T value) colorOf;
  final ValueChanged<T> onSelected;

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
          for (final T value in values)
            SdTagV3(
              label: labelOf(value),
              color: colorOf(value),
              selected: value == selected,
              onSelected: () => onSelected(value),
            ),
        ],
      ),
    ],
  );
}
