/// Riverpod wiring for `workspace`.
///
/// **Every other feature reads its currency and its stale threshold from
/// here**, so a screen never hardcodes `'USD'` and a policy never hardcodes
/// 60 days. When real workspaces arrive, only this file changes.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import 'domain/entities/workspace.dart';

/// The workspace the app is currently showing.
///
/// Null in live mode until workspace loading is written — the screens treat
/// that the same way they treat "still loading", which is correct: neither
/// state has a workspace to render.
final Provider<Workspace?> currentWorkspaceProvider = Provider<Workspace?>((
  Ref ref,
) {
  if (!ref.watch(dataModeProvider).isMock) return null;

  return ref.watch(mockStoreProvider).dataset.workspace;
});

/// The currency every money figure in the app is denominated in.
///
/// Falls back to USD when no workspace is loaded. A fallback rather than a
/// throw because it is only ever used to *format* a figure that is itself
/// null in that situation — an em dash needs a currency about as much as it
/// needs a font size.
final Provider<String> workspaceCurrencyProvider = Provider<String>((Ref ref) {
  return ref.watch(currentWorkspaceProvider)?.currency ?? 'USD';
});

/// How long a listing sits before this workspace calls it stale.
final Provider<Duration> staleThresholdProvider = Provider<Duration>((Ref ref) {
  return ref.watch(currentWorkspaceProvider)?.staleThreshold ??
      const Duration(days: 60);
});

final Provider<List<Member>> workspaceMembersProvider = Provider<List<Member>>((
  Ref ref,
) {
  if (!ref.watch(dataModeProvider).isMock) return const <Member>[];

  return ref.watch(mockStoreProvider).dataset.members;
});
