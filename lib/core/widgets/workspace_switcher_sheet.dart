import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../features/workspace/domain/entities/workspace.dart';
import '../../features/workspace/providers.dart';
import '../error/failure_presenter.dart';
import '../extensions/context_extensions.dart';
import '../router/app_routes.dart';

/// Slack's workspace switcher, in the shape a five-tab app can hold it.
///
/// Slack puts this at the top of a sidebar; there is no sidebar here (hard
/// rule 13 closes the tab list), so the trigger is Home's title and this is
/// what it opens. The parts that matter are kept: every business the seller
/// belongs to, the current one **ticked as well as tinted** (colour is never
/// the only signal), and creating another at the bottom of the same list
/// rather than hidden in settings.
///
/// In `core/widgets/` because Home opens it and More will: a widget more than
/// one feature uses cannot live in either feature's `presentation/`.
class WorkspaceSwitcherSheet extends ConsumerWidget {
  const WorkspaceSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const WorkspaceSwitcherSheet(),
  );

  Future<void> _switch(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    Navigator.of(context).pop();

    try {
      await ref
          .read(workspaceSwitchControllerProvider.notifier)
          .switchTo(workspaceId);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Workspace> workspaces = ref.watch(workspacesProvider);
    final String? currentId = ref.watch(currentWorkspaceIdProvider);

    return SdBottomSheetV3(
      title: context.l10n.workspaceSwitchTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: SdSpacingConstant.h200 * 2),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workspaces.length,
              itemBuilder: (BuildContext context, int index) {
                final Workspace workspace = workspaces[index];

                return _WorkspaceRow(
                  workspace: workspace,
                  isCurrent: workspace.id == currentId,
                  onTap: () => _switch(context, ref, workspace.id),
                );
              },
            ),
          ),
          const SdDividerV3(),
          _CreateWorkspaceRow(
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.workspaceCreate);
            },
          ),
        ],
      ),
    );
  }
}

class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.workspace,
    required this.isCurrent,
    required this.onTap,
  });

  final Workspace workspace;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    return InkWell(
      // Tapping the one already open is a no-op the controller short-circuits,
      // but leaving it tappable keeps the row heights and hit targets uniform.
      onTap: onTap,
      borderRadius: SdRadiusV3.cardAll,
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          children: <Widget>[
            SdIconTileV3(
              icon: Symbols.storefront_rounded,
              tint: accent,
              filled: isCurrent,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    workspace.name,
                    style: context.textTheme3.bodyMedium!.copyWith(
                      color: context.sdTheme3.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w600 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    workspace.currency,
                    style: context.textTheme3.bodySmall!.muted3(context),
                  ),
                ],
              ),
            ),
            if (isCurrent) SdIconV3(Symbols.check_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _CreateWorkspaceRow extends StatelessWidget {
  const _CreateWorkspaceRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: SdRadiusV3.cardAll,
    child: Padding(
      padding: SdContentPaddingV3.row,
      child: Row(
        children: <Widget>[
          SdIconV3(Symbols.add_rounded, color: context.colorScheme3.primary),
          SizedBox(width: SdSpacingConstant.w12),
          Text(
            context.l10n.workspaceCreateNew,
            style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
              color: context.colorScheme3.primary,
            ),
          ),
        ],
      ),
    ),
  );
}
