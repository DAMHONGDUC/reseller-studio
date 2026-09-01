import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// One figure in an analytics breakdown: a label, and a number on the right.
///
/// **Every value here is already a string**, formatted by the screen through
/// `context.money` or `context.percent` — which is where hard rule 5 lives, so
/// a figure the data cannot support arrives as `—` and this widget never has
/// to decide what to do about a null.
///
/// Tabular figures, because a column of money that shuffles sideways as it
/// updates is the one thing this app must not do.
class MetricRow extends StatelessWidget {
  const MetricRow({
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.isEmphasis = false,
    super.key,
  });

  final String label;
  final String value;

  /// A second line under the label, for a figure that needs its definition
  /// said out loud — "sold as a share of everything ever held".
  final String? caption;

  final Color? valueColor;

  /// The bottom line of a statement: heavier, and worth finding at a glance.
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: isEmphasis
                    ? context.textTheme3.bodyMedium!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      )
                    : context.textTheme3.bodyMedium!.muted3(context),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: context.textTheme3.bodySmall!.faint3(context),
                ),
            ],
          ),
        ),
        SizedBox(width: SdSpacingConstant.w12),
        Text(
          value,
          style:
              (isEmphasis
                      ? context.textTheme3.titleMedium!.bold3
                      : context.textTheme3.bodyMedium!.semiBold3)
                  .tabular3
                  .copyWith(color: valueColor ?? context.sdTheme3.textPrimary),
        ),
      ],
    ),
  );
}

/// A titled card of [MetricRow]s.
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.rows,
    this.leading,
    super.key,
  });

  final String title;
  final List<Widget> rows;

  /// A mark in front of the title — the colour of the marketplace this card
  /// is about. A widget, so this class never learns what the mark means.
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            SizedBox(width: SdSpacingConstant.w8),
          ],
          Expanded(
            child: Text(
              title,
              style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: SdSpacingConstant.h8),
      SdCardV3(child: Column(children: rows)),
    ],
  );
}
