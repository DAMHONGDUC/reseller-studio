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

/// The item's state, editable — four tags, each wearing its own colour.
///
/// **Tags rather than a picker sheet** — owner's rule. There are four states
/// and they are the answer to one question, so hiding them behind a row that
/// opens a sheet costs two taps to see what the choices even are. Laid out,
/// the seller reads the whole vocabulary at once.
///
/// **Switching is free** — owner's rule, and it is the newest one here. No
/// requirement is checked and no move is refused: the picker is where a
/// seller corrects what the app got wrong, and a correction that argues back
/// is the thing they came to fix. What the *verbs* do is unchanged —
/// `ItemTransition.check` still gates Mark as sold and the bulk paths, which
/// is where a missing price actually matters.
///
/// Setting `sold` still empties the count, because sold means sold out
/// however it was reached, and it writes **no order**: revenue and profit are
/// read from orders (hard rule 3), so a sale that has to show up in the
/// figures is recorded through Mark as sold.
class _StatusField extends ConsumerWidget {
  const _StatusField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ItemTagGroupField(
    label: context.l10n.itemStatus,
    children: <Widget>[
      for (final ItemStatus status in ItemStatus.values)
        SdTagV3(
          label: status.label(context),
          color: status.color(context),
          selected: state.status == status,
          onSelected: () => ref
              .read(itemFormControllerProvider.notifier)
              .selectStatus(status),
        ),
    ],
  );
}
