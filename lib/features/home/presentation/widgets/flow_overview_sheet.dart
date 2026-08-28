import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../more/workflow_constant.dart';

/// How a seller runs their week with this app, step by step and spelled out.
///
/// **A sheet rather than a screen** — owner's rule. The question it answers is
/// asked while standing somewhere else in the app, and pushing a route would
/// cost the seller their place.
///
/// **A document, not a menu**: it takes a fixed share of the screen
/// (`SdBottomSheetV3.heightFactor`) and scrolls, because this is the answer to
/// "how do I use this" and a list of nine nouns is not an answer. Every step
/// says what it is, whether the app ever asks for it, what the seller actually
/// does, and opens the screen that performs it.
///
/// It draws `WorkflowConstant.steps`, the same data About's diagram uses: a
/// second list written for this sheet is how the app ends up teaching two
/// workflows.
class FlowOverviewSheet extends StatelessWidget {
  const FlowOverviewSheet({super.key});

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const FlowOverviewSheet(),
  );

  /// Most of the screen, and deliberately not all of it: the strip of page
  /// left showing is what says the sheet can be dismissed.
  static const double heightFactor = 0.85;

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: context.l10n.flowOverviewTitle,
    heightFactor: heightFactor,
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Text(
          context.l10n.flowOverviewIntro,
          style: context.textTheme3.bodySmall!.muted3(context),
        ),
        SizedBox(height: SdSpacingConstant.h16),
        for (int i = 0; i < WorkflowConstant.steps.length; i++) ...<Widget>[
          if (i > 0) SdDividerV3(gap: SdSpacingConstant.h16),
          _FlowStep(
            // Keyed by kind so a step can be found on its own — the badge
            // belongs to one step, and asserting on a loose count would pass
            // with the right number in the wrong places.
            key: ValueKey<WorkflowKind>(WorkflowConstant.steps[i].kind),
            step: WorkflowConstant.steps[i],
            position: i + 1,
          ),
        ],
        SizedBox(height: SdSpacingConstant.h16),
        // The chain is a loop, and the last step feeds the first — said in
        // words rather than drawn as an arrow up the whole sheet.
        Text(
          context.l10n.flowOverviewLoop,
          style: context.textTheme3.bodySmall!.muted3(context),
        ),
      ],
    ),
  );
}

/// One step, at the length that answers the question.
///
/// **The number is the whole reason this is not About's diagram.** A sheet is
/// read top to bottom in one go, so an ordinal says "third of nine" faster
/// than a rail does, and it survives the block wrapping to ten lines.
class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.step, required this.position, super.key});

  final WorkflowStep step;

  /// 1-based, because it is read rather than indexed.
  final int position;

  /// The numbered disc's own size — what it is, not configuration about it.
  static double get discSize => SdSpacingConstant.r28;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
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
            Flexible(
              child: Text(
                WorkflowLabel.title(context, step.kind),
                style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
            ),
            if (step.isOptional) ...<Widget>[
              SizedBox(width: SdSpacingConstant.w8),
              // Neutral: optional is not a warning, and the word is what
              // carries it — colour is never the only signal.
              SdBadgeV3(label: context.l10n.commonOptional),
            ],
          ],
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          WorkflowLabel.detail(context, step.kind),
          style: context.textTheme3.bodySmall!.muted3(context),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        for (final String line in WorkflowLabel.how(context, step.kind))
          _FlowStepLine(text: line),
        SizedBox(height: SdSpacingConstant.h8),
        SdButtonV3(
          variant: SdButtonVariantV3.text,
          size: SdButtonSizeV3.small,
          label: context.l10n.flowOverviewOpen,
          icon: Symbols.arrow_forward_rounded,
          onPressed: () {
            // Closes first, so the seller lands on the step rather than
            // reading the sheet again over it.
            Navigator.of(context).pop();
            context.push(step.route);
          },
        ),
      ],
    );
  }
}

/// One instruction under a step.
///
/// A dot rather than a bullet glyph, and hidden from screen readers: the
/// sentence beside it is the content, and "bullet" read out three times a step
/// is nine words of noise per screen.
class _FlowStepLine extends StatelessWidget {
  const _FlowStepLine({required this.text});

  final String text;

  /// The marker's own size and the space it is centred in.
  static double get dotSize => SdSpacingConstant.r4;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: SdSpacingConstant.h6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: Container(
            width: dotSize,
            height: dotSize,
            // Lines the dot up with the middle of the first line of text
            // rather than with the top of its box.
            margin: EdgeInsets.only(top: SdSpacingConstant.h8),
            decoration: BoxDecoration(
              color: context.sdTheme3.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: SdSpacingConstant.w8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
