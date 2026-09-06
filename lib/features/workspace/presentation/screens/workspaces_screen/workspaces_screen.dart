import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_row_icon_button.dart';
import '../../../../../core/widgets/plan_limit_meters.dart';
import '../../../../subscription/domain/enums/plan_allowance.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../../domain/entities/workspace.dart';
import '../../../providers.dart';

part 'workspaces_screen_row.dart';

/// Businesses — every business this seller belongs to, and the ceiling on how
/// many they may have.
///
/// **The switcher sheet stays what it is: a switcher.** It opens from Home's
/// title mid-task and closes the moment a business is picked, which is the
/// wrong surface for the plan meter and for an empty state. This screen is
/// where the list is *managed* — how many are allowed, how many are used, and
/// the one action that spends the next slot.
///
/// The interaction is the sheet's, deliberately unchanged: tapping a row
/// switches to that business, the pencil beside it opens the business details
/// screen. Two gestures that do different things must not be the same gesture
/// in two places.
class WorkspacesScreen extends ConsumerWidget {
  const WorkspacesScreen({super.key});

  /// The one ceiling this screen's records count against.
  static const List<PlanAllowance> _meterAllowances = <PlanAllowance>[
    PlanAllowance.workspaces,
  ];

  Future<void> _switch(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
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

  /// Opens the create flow, or says why the plan will not allow it.
  ///
  /// Checked before the form opens, never after the seller has named a
  /// business — the same rule Quick Add and Record sale are written to.
  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final PlanBlock block = ref.read(addWorkspaceBlockProvider);

    if (block == PlanBlock.none) {
      await context.push(AppRoutes.workspaceCreate);

      return;
    }

    if (!context.mounted) return;

    await PlanBlockSheet.show(
      context,
      block: block,
      plan: ref.read(currentPlanProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Workspace> workspaces = ref.watch(workspacesProvider);
    final String? currentId = ref.watch(currentWorkspaceIdProvider);

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: context.l10n.workspacesTitle),
      addLabel: context.l10n.workspaceAddTitle,
      onAdd: () => _create(context, ref),
      body: workspaces.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.storefront,
              title: context.l10n.workspacesEmptyTitle,
              message: context.l10n.workspacesEmptyBody,
              action: SdButtonV3(
                variant: SdButtonVariantV3.primary,
                label: context.l10n.workspaceAddTitle,
                onPressed: () => _create(context, ref),
              ),
            )
          : ListView(
              padding: AppAddFabScaffold.listPadding(context),
              children: <Widget>[
                // The screen places it, the way every other list screen does
                // — the gap under an app bar has one owner and one value.
                SizedBox(height: SdContentPaddingV3.topGap),
                // Above the list, because it is the answer to the question the
                // create button is about to ask.
                const PlanLimitMeters(allowances: _meterAllowances),
                // The gap belongs to the card under the meter, and exists
                // only when the meter does.
                if (PlanLimitMeters.cappedIn(
                  ref,
                  allowances: _meterAllowances,
                ).isNotEmpty)
                  SizedBox(height: SdContentPaddingV3.listItemGap),
                AppListCard(
                  children: workspaces
                      .map(
                        (Workspace workspace) => _WorkspaceRow(
                          workspace: workspace,
                          isCurrent: workspace.id == currentId,
                          onTap: () => _switch(context, ref, workspace.id),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}
