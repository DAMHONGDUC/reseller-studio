part of 'item_form_screen.dart';

/// A titled group of fields inside one card.
///
/// Grouping rather than one flat column: the form asks about five different
/// subjects, and a seller filling in only the pricing should be able to find
/// where it starts and stops.
class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: context.textTheme3.titleSmall!.semiBold3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
      ),
      SizedBox(height: SdSpacingConstant.h8),
      SdCardV3(
        child: Column(
          children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              children[i],
              if (i != children.length - 1)
                SizedBox(height: SdSpacingConstant.h16),
            ],
          ],
        ),
      ),
    ],
  );
}

/// The item's state, editable.
///
/// **The same field the detail screen draws** — `ItemStatusField` holds the
/// tags and the rule; this is the form's wiring to it, so the two screens
/// cannot answer one question two ways.
class _StatusField extends ConsumerWidget {
  const _StatusField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ItemStatusField(
    selected: state.status,
    onSelected: (ItemStatus status) =>
        ref.read(itemFormControllerProvider.notifier).selectStatus(status),
  );
}
