part of 'orders_screen.dart';

/// `Sold → Shipped → Paid out`, as three dots joined by two bars.
///
/// **A track rather than a status word** — a status says where the order is;
/// the track also says what is left, which is the question a seller scanning
/// the list is asking. Drawn in ink: reached stages in the secondary grey, the
/// next one ringed in the primary ink, and in danger only when it is late.
class _OrderProgressTrack extends StatelessWidget {
  const _OrderProgressTrack({
    required this.reached,
    required this.next,
    required this.isOverdue,
  });

  final Set<OrderStage> reached;
  final OrderStage? next;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final Color done = context.sdTheme3.textSecondary;
    final Color pending = context.sdTheme3.border;
    final Color upcoming = isOverdue
        ? context.sdTheme3.danger
        : context.sdTheme3.textPrimary;

    return Semantics(
      label: OrderStage.values
          .where(reached.contains)
          .map((OrderStage stage) => stage.label(context))
          .join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final OrderStage stage in OrderStage.values) ...<Widget>[
                if (stage != OrderStage.values.first)
                  Expanded(
                    child: Container(
                      height: SdSpacingConstant.h2,
                      color: reached.contains(stage) ? done : pending,
                    ),
                  ),
                _StageDot(
                  fill: reached.contains(stage) ? done : null,
                  ring: stage == next ? upcoming : pending,
                ),
              ],
            ],
          ),
          SizedBox(height: SdSpacingConstant.h4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final OrderStage stage in OrderStage.values)
                Text(
                  stage.label(context),
                  style: stage == next
                      ? context.textTheme3.bodySmall!.semiBold3.copyWith(
                          color: upcoming,
                        )
                      : context.textTheme3.bodySmall!.faint3(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One stage: filled when reached, an empty ring otherwise.
class _StageDot extends StatelessWidget {
  const _StageDot({required this.fill, required this.ring});

  final Color? fill;
  final Color ring;

  @override
  Widget build(BuildContext context) => Container(
    width: SdSpacingConstant.w12,
    height: SdSpacingConstant.w12,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fill ?? context.sdTheme3.surfaceElevated,
      border: fill == null
          ? Border.all(color: ring, width: SdSpacingConstant.w2)
          : null,
    ),
  );
}
