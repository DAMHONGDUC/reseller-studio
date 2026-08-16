part of 'order_detail_screen.dart';

/// What has happened to this order, in order.
///
/// **Built from the order's own timestamps, not from an event log.** The
/// audit log is written by Cloud Functions and is not deployed yet; the dates
/// on the document are facts the app already has, and a timeline that needs a
/// backend to render is a blank card until one exists.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final List<_TimelineEntry> entries = <_TimelineEntry>[
      _TimelineEntry(context.l10n.orderOrdered, order.orderedAt),
      if (order.shippedAt != null)
        _TimelineEntry(context.l10n.orderStatusShipped, order.shippedAt!),
      if (order.deliveredAt != null)
        _TimelineEntry(context.l10n.orderStatusDelivered, order.deliveredAt!),
    ];

    return SdCardV3(
      child: Column(
        children: entries
            .map(
              (_TimelineEntry entry) => _OrderDetailRow(
                label: entry.label,
                value: DateTimeUtils.dateTime(
                  entry.at,
                  locale: context.localeTag,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// One dated step. A value type rather than a record so the list reads as
/// what it is at every call site.
class _TimelineEntry {
  const _TimelineEntry(this.label, this.at);

  final String label;
  final DateTime at;
}
