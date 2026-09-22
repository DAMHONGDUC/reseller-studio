import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/account/account_kind.dart';
import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/local/drain/drain_destination.dart';
import '../../../../core/widgets/app_sheet_action_row.dart';
import '../../../../core/widgets/app_sheet_option_list.dart';
import '../../domain/entities/workspace.dart';
import '../../providers.dart';
import '../controllers/guest_drain_controller.dart';

/// Starts the drain once, as soon as there is an account to drain into.
///
/// **A gate rather than a step in the sign-in flow.** Signing in is not the
/// moment the records can move: the profile, the workspace list and the
/// resolved business all arrive afterwards, on their own streams. This sits
/// above the shell and fires when all three have — which is also why it is
/// idempotent, because they can arrive more than once.
///
/// It renders its child unchanged. Nothing waits on the drain
/// (`docs/rules/GUEST_MODE.md`): the seller keeps looking at their own
/// records the whole time, read from whichever store currently holds them.
class GuestDrainGate extends ConsumerStatefulWidget {
  const GuestDrainGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<GuestDrainGate> createState() => _GuestDrainGateState();
}

class _GuestDrainGateState extends ConsumerState<GuestDrainGate> {
  /// So a rebuild — or a second stream landing — does not ask twice.
  bool _asked = false;

  Future<void> _maybeDrain() async {
    if (_asked) return;

    _asked = true;

    try {
      final DrainDestination? destination = await ref
          .read(guestDrainControllerProvider.notifier)
          .decide();

      if (destination == null || !mounted) return;

      switch (destination) {
        case DrainIntoNewWorkspace():
          await ref
              .read(guestDrainControllerProvider.notifier)
              .intoNewWorkspace();
        case DrainNeedsChoice(:final List<Workspace> candidates):
          await _ask(candidates);
        case DrainIntoWorkspace(:final String workspaceId):
          await ref
              .read(guestDrainControllerProvider.notifier)
              .intoWorkspace(workspaceId);
      }
    } catch (error) {
      // Already logged by the controller; the seller keeps their records
      // either way, so this is a message rather than a failure state.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );

      // Not `_asked = false`: a drain that failed is retried on the next
      // launch, not immediately, so a broken connection does not put this
      // sheet in front of the seller over and over.
    }
  }

  Future<void> _ask(List<Workspace> candidates) =>
      GuestDrainSheet.show(context, candidates);

  @override
  Widget build(BuildContext context) {
    final bool linked = ref.watch(accountKindProvider) == AccountKind.linked;
    final bool ready = ref.watch(currentWorkspaceIdProvider) != null;

    if (linked && ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeDrain());
    }

    return widget.child;
  }
}

/// Which business a guest's records should join.
///
/// **Not optional, and not defaulted** — owner's rule: emptying a guest's
/// stock into a business that already has real books is a merge no rule can
/// undo, so the seller names the destination themselves.
class GuestDrainSheet extends ConsumerWidget {
  const GuestDrainSheet({required this.candidates, super.key});

  final List<Workspace> candidates;

  static Future<void> show(BuildContext context, List<Workspace> candidates) =>
      showSdBottomSheetV3<void>(
        context: context,
        // Dismissing leaves the records on the device, which is safe and
        // recoverable: the next launch asks again.
        builder: (BuildContext context) =>
            GuestDrainSheet(candidates: candidates),
      );

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    String? workspaceId,
  ) async {
    Navigator.of(context).pop();

    final GuestDrainController controller = ref.read(
      guestDrainControllerProvider.notifier,
    );

    if (workspaceId == null) {
      await controller.intoNewWorkspace();

      return;
    }

    await controller.intoWorkspace(workspaceId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdBottomSheetV3(
    title: context.l10n.guestSyncTitle,
    closeTooltip: context.l10n.commonClose,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.guestSyncBody,
          style: context.textTheme3.bodyMedium!.muted3(context),
        ),
        SizedBox(height: SdSpacingConstant.h16),
        AppSheetOptionList(
          itemCount: candidates.length + 1,
          itemBuilder: (BuildContext context, int index) =>
              index == candidates.length
              // Last, not first: the default a seller reaches for is the
              // business they already keep books in, and a new one is the
              // deliberate answer.
              ? AppSheetActionRow(
                  icon: AppIconConstant.add,
                  label: context.l10n.guestSyncKeepSeparate,
                  onTap: () => _choose(context, ref, null),
                )
              : AppSheetActionRow(
                  icon: AppIconConstant.business,
                  label: candidates[index].name,
                  onTap: () => _choose(context, ref, candidates[index].id),
                ),
        ),
      ],
    ),
  );
}
