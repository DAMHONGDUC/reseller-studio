import '../../../features/workspace/domain/entities/workspace.dart';

/// Where a guest's records are about to go, and whether the seller has to be
/// asked first.
///
/// Owner's rule (`docs/rules/GUEST_MODE.md`):
///
/// | The account being signed into | What happens |
/// |---|---|
/// | has **no** workspace | the guest business is pushed up whole |
/// | **already has** one or more | **ask** — a dialog names them all |
///
/// The dialog is not optional. Emptying a guest's stock into a business that
/// already has real books is a merge the seller may not want, and no rule can
/// undo it afterwards.
sealed class DrainDestination {
  const DrainDestination();

  /// What to do for an account holding [existing] workspaces.
  static DrainDestination forAccount(List<Workspace> existing) {
    if (existing.isEmpty) return const DrainIntoNewWorkspace();

    return DrainNeedsChoice(existing);
  }
}

/// Nothing to merge with: the guest business becomes the account's.
class DrainIntoNewWorkspace extends DrainDestination {
  const DrainIntoNewWorkspace();
}

/// The seller picks, and nothing moves until they have.
class DrainNeedsChoice extends DrainDestination {
  const DrainNeedsChoice(this.candidates);

  /// Every business the account already holds. The guest's own is not in the
  /// list — choosing it is the [DrainIntoNewWorkspace] answer, offered
  /// alongside these as "keep them separate".
  final List<Workspace> candidates;
}

/// The seller answered, and this is the business they named.
class DrainIntoWorkspace extends DrainDestination {
  const DrainIntoWorkspace(this.workspaceId);

  final String workspaceId;
}
