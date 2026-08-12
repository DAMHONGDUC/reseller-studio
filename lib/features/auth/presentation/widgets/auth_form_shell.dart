import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// The frame every auth screen wears: a headline, a line under it, and the
/// form.
///
/// Extracted the moment sign-up joined login rather than later — three
/// screens each drawing their own version of the same header is how the
/// spacing between them drifts apart.
///
/// Its own widget rather than a `_build` method, so Flutter can scope the
/// rebuild when a form field below it changes.
class AuthFormShell extends StatelessWidget {
  const AuthFormShell({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    body: SafeArea(
      child: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdSpacingConstant.h64),
          Text(
            title,
            style: context.textTheme3.headlineMedium!.bold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(subtitle, style: context.textTheme3.bodyMedium!.muted3(context)),
          SizedBox(height: SdSpacingConstant.h40),
          ...children,
        ],
      ),
    ),
  );
}
