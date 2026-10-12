import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_bullet_line.dart';
import '../../../../../core/widgets/legal_links_card.dart';
import '../../../workflow_constant.dart';

part 'about_screen_workflow.dart';

/// About — what this app is, and the loop it exists to serve.
///
/// **The workflow is the product's argument, so it is drawn rather than
/// described.** A seller who has only ever used a spreadsheet has no reason
/// to expect that recording a purchase is what makes a profit figure true
/// later. Showing the chain, with each link opening the screen that performs
/// it, is what turns nine features into one workflow.
///
/// **Two guides, one rail.** Reselling and dropshipping share Sell, Profit
/// and Analyze but not the steps around them, so a switch picks which loop is
/// drawn rather than one diagram trying to be both.
///
/// No version fetch, no network, no repository — everything here is a
/// compile-time constant or a string. The screen must open instantly and work
/// with no account, because it is also where somebody looks when nothing else
/// is working.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  WorkflowGuide _guide = WorkflowGuide.reselling;

  @override
  Widget build(BuildContext context) {
    final bool isDropship = _guide == WorkflowGuide.dropshipping;

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.aboutTitle),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _Masthead(),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          SdSectionHeaderV3(
            title: context.l10n.aboutWorkflowTitle,
            subtitle: isDropship
                ? context.l10n.aboutDropshipSubtitle
                : context.l10n.aboutWorkflowSubtitle,
            first: true,
          ),
          _GuidePicker(
            guide: _guide,
            onChanged: (WorkflowGuide guide) => setState(() => _guide = guide),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          _Workflow(steps: WorkflowConstant.of(_guide)),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            isDropship
                ? context.l10n.aboutDropshipLoop
                : context.l10n.aboutWorkflowLoop,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          // Reachable with no account: About is outside the sign-in gate, and
          // a reviewer looking for the privacy policy looks here first.
          SdSectionHeaderV3(title: context.l10n.legalSection),
          const LegalLinksCard(),
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      ),
    );
  }
}

/// Which business's loop the rail draws.
class _GuidePicker extends StatelessWidget {
  const _GuidePicker({required this.guide, required this.onChanged});

  final WorkflowGuide guide;
  final ValueChanged<WorkflowGuide> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: SdSpacingConstant.w8,
    children: <Widget>[
      for (final WorkflowGuide option in WorkflowGuide.values)
        SdFilterChipV3(
          label: switch (option) {
            WorkflowGuide.reselling => context.l10n.aboutGuideReselling,
            WorkflowGuide.dropshipping => context.l10n.aboutGuideDropshipping,
          },
          selected: option == guide,
          onSelected: () => onChanged(option),
        ),
    ],
  );
}

/// The app's name, what it is for, and the principle it is built on.
class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SdIconTileV3(
              icon: AppIconConstant.storefront,
              tint: context.colorScheme3.primary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppEnv.appDisplayName,
                    style: context.textTheme3.titleMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                  Text(
                    context.l10n.aboutTagline,
                    style: context.textTheme3.bodySmall!.copyWith(
                      color: context.sdTheme3.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h16),
        Text(
          context.l10n.aboutIntro,
          style: context.textTheme3.bodyMedium!.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          context.l10n.aboutIntroDropship,
          style: context.textTheme3.bodyMedium!.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        // The principle the whole product is judged against, set apart rather
        // than folded into the paragraph above it — it is the sentence a
        // seller should remember.
        Container(
          padding: SdContentPaddingV3.card,
          decoration: BoxDecoration(
            color: context.sdTheme3.surfaceSunken,
            borderRadius: SdRadiusV3.cardAll,
          ),
          child: Text(
            context.l10n.aboutPrinciple,
            style: context.textTheme3.bodyMedium!.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
