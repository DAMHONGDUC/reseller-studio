import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_sheet_option_list.dart';
import '../../../more/workflow_constant.dart';

/// How a seller runs their week with this app, step by step.
///
/// **A sheet rather than a screen** — owner's rule. The question it answers is
/// asked while standing somewhere else in the app, and pushing a route would
/// cost the seller their place to read nine lines.
///
/// It draws `WorkflowConstant.steps`, the same data About's diagram uses:
/// a second list written for this sheet is how the app ends up teaching two
/// workflows. Each row opens the screen that performs its step, so this is a
/// way in rather than a picture.
class FlowOverviewSheet extends StatelessWidget {
  const FlowOverviewSheet({super.key});

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const FlowOverviewSheet(),
  );

  /// How tall the steps may grow before they scroll inside the sheet. Nine
  /// two-line rows do not fit a phone, and a sheet taller than the screen is
  /// a sheet with its first step off the top.
  static double get stepsMaxHeight => SdSpacingConstant.h200 * 2;

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: context.l10n.flowOverviewTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.flowOverviewIntro,
          style: context.textTheme3.bodySmall!.muted3(context),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        AppSheetOptionList(
          maxHeight: stepsMaxHeight,
          itemCount: WorkflowConstant.steps.length,
          itemBuilder: (BuildContext context, int index) => _FlowStepRow(
            step: WorkflowConstant.steps[index],
            position: index + 1,
          ),
        ),
      ],
    ),
  );
}

/// One step: its number, what it is, what it is for, and whether the app ever
/// asks for it.
///
/// **The number is the whole reason this is not About's diagram.** A sheet is
/// read top to bottom in one go, so an ordinal says "third of nine" faster
/// than a rail does, and it survives the row wrapping to three lines.
class _FlowStepRow extends StatelessWidget {
  const _FlowStepRow({required this.step, required this.position});

  final WorkflowStep step;

  /// 1-based, because it is read rather than indexed.
  final int position;

  /// The numbered disc's own size — what it is, not configuration about it.
  static double get discSize => SdSpacingConstant.r28;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    return InkWell(
      onTap: () {
        // Closes first, so the seller lands on the step rather than reading
        // the sheet again over it.
        Navigator.of(context).pop();
        context.push(step.route);
      },
      borderRadius: SdRadiusV3.cardAll,
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: discSize,
              height: discSize,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: SdIconTileV3.backgroundOpacity),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: context.textTheme3.labelSmall!.semiBold3.copyWith(
                    color: accent,
                  ),
                ),
              ),
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          WorkflowLabel.title(context, step.kind),
                          style: context.textTheme3.bodyMedium!.semiBold3
                              .copyWith(color: context.sdTheme3.textPrimary),
                        ),
                      ),
                      if (step.isOptional) ...<Widget>[
                        SizedBox(width: SdSpacingConstant.w8),
                        // Neutral: optional is not a warning, and the word is
                        // what carries it — colour is never the only signal.
                        SdBadgeV3(label: context.l10n.commonOptional),
                      ],
                    ],
                  ),
                  SizedBox(height: SdSpacingConstant.h2),
                  Text(
                    WorkflowLabel.detail(context, step.kind),
                    style: context.textTheme3.bodySmall!.muted3(context),
                  ),
                ],
              ),
            ),
            SdIconV3(
              Icons.chevron_right_rounded,
              size: SdIconV3.smallSize,
              color: context.sdTheme3.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
