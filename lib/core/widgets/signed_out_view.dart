import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../features/auth/providers.dart';
import '../extensions/context_extensions.dart';
import '../router/app_routes.dart';

/// What a tab shows before anyone signs in — owner's rule.
///
/// **One view for all of them, not each tab's own empty state.** A tab that
/// rendered its real empty list would be saying "you have no orders", which is
/// a claim about the seller's business; the truth is that nobody has said
/// whose business to show. Hard rule 5 is the same idea one level down: an
/// unknown is never drawn as a zero.
///
/// More is the exception and is deliberately not wrapped — Settings has to be
/// reachable without an account so theme and language can be changed.
class SignedOutView extends StatelessWidget {
  const SignedOutView({required this.title, super.key});

  /// The tab's own name, so the bar still says where you are.
  final String title;

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    appBar: SdAppBarV3(title: title, automaticallyImplyLeading: false),
    body: Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SdIconV3(
              Symbols.lock_rounded,
              size: SdSpacingConstant.r44,
              color: context.sdTheme3.textSecondary,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            Text(
              context.l10n.workspaceSignInPrompt,
              textAlign: TextAlign.center,
              style: context.textTheme3.bodyMedium!.muted3(context),
            ),
            SizedBox(height: SdSpacingConstant.h24),
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.workspaceSignInAction,
              onPressed: () => context.push(AppRoutes.login),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Wraps a tab that means nothing without an account.
///
/// **The check lives here and in the router, nowhere else.** Hard rule 1's
/// point survives the preview shell: no screen decides for itself whether it
/// may render — Home, Inventory, Orders and Analytics are each written as if
/// there is always a workspace, and this is what makes that true.
class AuthedTab extends ConsumerWidget {
  const AuthedTab({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      (ref.watch(isSignedInProvider) ?? false)
      ? child
      : SignedOutView(title: title);
}
