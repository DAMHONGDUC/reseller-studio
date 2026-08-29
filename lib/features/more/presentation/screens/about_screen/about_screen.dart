import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
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
/// No version fetch, no network, no repository — everything here is a
/// compile-time constant or a string. The screen must open instantly and work
/// with no account, because it is also where somebody looks when nothing else
/// is working.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    appBar: SdAppBarV3(title: context.l10n.aboutTitle),
    body: ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        const _Masthead(),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        SdSectionHeaderV3(
          title: context.l10n.aboutWorkflowTitle,
          subtitle: context.l10n.aboutWorkflowSubtitle,
          first: true,
        ),
        const _Workflow(),
        SizedBox(height: SdSpacingConstant.h16),
        Text(
          context.l10n.aboutWorkflowLoop,
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
