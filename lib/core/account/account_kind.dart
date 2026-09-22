import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/providers.dart';

/// Which store the app is reading and writing.
///
/// **The one seam between guest mode and an account**
/// (`docs/rules/GUEST_MODE.md`). Every repository provider branches on this
/// and nothing else does: **never write `if (isGuest)` at a call site** — no
/// screen, controller or service learns that guest mode exists.
enum AccountKind {
  /// Signed out. Records live in the local Drift database, on this device
  /// only, and go nowhere.
  guest,

  /// Signed in. Records live in Firestore, whose own offline cache is the
  /// local half.
  linked,
}

/// Resolves to [AccountKind.guest] while auth is still loading, and that is
/// deliberate: a guest shell is a working app, so there is nothing to hide
/// behind a splash for. The router still holds the splash until auth resolves
/// (hard rule 1) — what this stops is a repository throwing in the frame
/// before it does.
final Provider<AccountKind> accountKindProvider = Provider<AccountKind>((
  Ref ref,
) {
  return (ref.watch(isSignedInProvider) ?? false)
      ? AccountKind.linked
      : AccountKind.guest;
});
