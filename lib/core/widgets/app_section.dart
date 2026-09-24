import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import 'app_list_row.dart';

/// A section heading over the card it heads — one widget, so the two cannot
/// drift apart.
///
/// - the heading sits on the card's left edge, and
///   `SdContentPaddingV3.sectionHeader` holds it off the card
///   (`docs/rules/DESIGN_SYSTEM.md`)
/// - **it carries no gutter**: a `screen()` list places it, and a `fullBleed`
///   one wraps it in `SdContentPaddingV3.horizontal`, like any shared widget
/// - [AppSection.rows] is the list-of-rows card; the default constructor puts
///   any content in a plain `SdCardV3`
class AppSection extends StatelessWidget {
  const AppSection({
    required this.title,
    required Widget this.child,
    this.subtitle,
    this.leading,
    this.action,
    this.first = false,
    this.padding,
    this.borderColor,
    super.key,
  }) : children = null;

  /// [AppListRow]s in an `AppListCard`, hairlines between them.
  const AppSection.rows({
    required this.title,
    required List<Widget> this.children,
    this.subtitle,
    this.leading,
    this.action,
    this.first = false,
    this.borderColor,
    super.key,
  }) : child = null,
       padding = null;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? action;

  /// Drops the gap above — see `SdSectionHeaderV3.first`.
  final bool first;

  final Widget? child;
  final List<Widget>? children;

  /// The card's inner padding; null keeps `SdCardV3`'s own.
  final EdgeInsets? padding;

  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final List<Widget>? rows = children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(
          title: title,
          subtitle: subtitle,
          leading: leading,
          action: action,
          first: first,
        ),
        if (rows != null)
          AppListCard(borderColor: borderColor, children: rows)
        else
          SdCardV3(
            padding: padding,
            borderColor: borderColor,
            child: child ?? const SizedBox.shrink(),
          ),
      ],
    );
  }
}
