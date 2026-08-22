/// Riverpod wiring for `workspace`.
///
/// **Every other feature reads its currency and its stale threshold from
/// here**, so a screen never hardcodes `'USD'` and a policy never hardcodes
/// 60 days. It is also where the app decides *whose* data the six business
/// repositories are pointed at — [workspaceContextProvider] is the seam
/// between "signed in" and "reading a business".
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/config/dev_flags.dart';
import '../../core/firestore/workspace_collections.dart';
import '../../core/firestore/workspace_context.dart';
import '../auth/providers.dart';
import '../listings/domain/enums/listing_status.dart';
import '../mock_data/data/in_memory_repositories.dart';
import '../mock_data/providers.dart';
import '../pricing/domain/services/profit_calculator.dart';
import 'data/repositories/firestore_workspace_repository.dart';
import 'domain/entities/user_profile.dart';
import 'domain/entities/workspace.dart';
import 'domain/repositories/workspace_repository.dart';
import 'presentation/controllers/workspace_switch_controller.dart';

/// The `FirebaseFirestore` instance, behind a provider so a test can override
/// it and so nothing in a feature reaches for the singleton.
final Provider<FirebaseFirestore> firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((Ref ref) => FirebaseFirestore.instance);

final Provider<WorkspaceRepository> workspaceRepositoryProvider =
    Provider<WorkspaceRepository>((Ref ref) {
      // Mock first, exactly like every business repository: put the Firestore
      // branch first and a demo run reaches for a backend that is not there.
      if (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock) {
        return InMemoryWorkspaceRepository(ref.watch(mockStoreProvider));
      }

      return FirestoreWorkspaceRepository(ref.watch(firebaseFirestoreProvider));
    });

/// The signed-in person's own record — name, email, and which workspaces they
/// belong to.
///
/// Not read in mock mode: there is no account, and the mock dataset carries
/// its own workspace.
final StreamProvider<UserProfile?> userProfileProvider =
    StreamProvider<UserProfile?>((Ref ref) {
      final String? uid = ref.watch(currentUidProvider);

      if (uid == null ||
          (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock)) {
        return Stream<UserProfile?>.value(null);
      }

      return ref.watch(workspaceRepositoryProvider).watchProfile(uid);
    });

/// Which workspace the app is showing, by id.
final Provider<String?> currentWorkspaceIdProvider = Provider<String?>((
  Ref ref,
) {
  if (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock) {
    return ref.watch(mockStoreProvider).dataset.workspace.id;
  }

  return ref.watch(userProfileProvider).value?.resolvedWorkspaceId;
});

/// The live workspace document.
// See `itemProvider` for why a family's type is inferred rather than written.
// ignore: type_annotate_public_apis
final liveWorkspaceProvider = StreamProvider.family<Workspace?, String>(
  (Ref ref, String workspaceId) =>
      ref.watch(workspaceRepositoryProvider).watchWorkspace(workspaceId),
);

/// The workspace the app is currently showing.
///
/// Null while it is still loading, and null when the account has none — the
/// router tells those apart through [workspaceStatusProvider], because one is
/// a splash screen and the other is onboarding.
final Provider<Workspace?> currentWorkspaceProvider = Provider<Workspace?>((
  Ref ref,
) {
  // Both modes go through the same stream on purpose. Reading the seed
  // directly was simpler and made the demo the one place a workspace could
  // not be edited — the repository is what Settings writes through.
  if (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock) {
    final Workspace seed = ref.watch(mockStoreProvider).dataset.workspace;

    return ref.watch(liveWorkspaceProvider(seed.id)).value ?? seed;
  }

  final String? id = ref.watch(currentWorkspaceIdProvider);

  if (id == null) return null;

  return ref.watch(liveWorkspaceProvider(id)).value;
});

/// Where onboarding has got to.
///
/// The router branches on this, so the three cases have to be distinguishable:
/// a user whose profile has not loaded must see the splash, not the workspace
/// form, or a returning seller is asked to create a second business every time
/// they open the app.
enum WorkspaceStatus {
  /// The profile has not arrived yet. Show the splash.
  loading,

  /// Signed in with no workspace. Onboarding.
  none,

  /// Ready to render the app.
  ready,
}

final Provider<WorkspaceStatus> workspaceStatusProvider =
    Provider<WorkspaceStatus>((Ref ref) {
      if (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock) {
        return WorkspaceStatus.ready;
      }

      final AsyncValue<UserProfile?> profile = ref.watch(userProfileProvider);

      if (profile.isLoading && !profile.hasValue) {
        return WorkspaceStatus.loading;
      }

      // A failed profile read is treated as "no workspace" rather than
      // "loading": the user gets a screen they can act on instead of a splash
      // that never resolves.
      return profile.value?.resolvedWorkspaceId == null
          ? WorkspaceStatus.none
          : WorkspaceStatus.ready;
    });

/// What the six business repositories are pointed at, or null when there is
/// nothing to point them at yet.
///
/// Null means signed out, or signed in with onboarding unfinished. Both are
/// states the router keeps the user out of the app for, so a repository that
/// finds a null here is being read from a screen that should not be on
/// screen — which is why the repository providers say so out loud rather than
/// returning an empty list.
final Provider<WorkspaceContext?> workspaceContextProvider =
    Provider<WorkspaceContext?>((Ref ref) {
      final String? uid = ref.watch(currentUidProvider);
      final String? workspaceId = ref.watch(currentWorkspaceIdProvider);

      if (uid == null || workspaceId == null) return null;

      return WorkspaceContext(
        collections: WorkspaceCollections(
          ref.watch(firebaseFirestoreProvider),
          workspaceId,
        ),
        currency: ref.watch(workspaceCurrencyProvider),
        uid: uid,
      );
    });

final NotifierProvider<WorkspaceSwitchController, void>
workspaceSwitchControllerProvider =
    NotifierProvider<WorkspaceSwitchController, void>(
      WorkspaceSwitchController.new,
    );

/// Every business this person belongs to, for the switcher.
///
/// Folded from `UserProfile.workspaceIds` rather than queried: the security
/// rules scope member reads to one workspace at a time on purpose, so "which
/// businesses am I in?" has no server-side answer a client may ask (see
/// [UserProfile.workspaceIds]).
///
/// **Documents still loading are skipped, not rendered as blanks.** The list
/// fills in as each arrives, which is what stops the sheet flashing a column
/// of empty rows on open.
final Provider<List<Workspace>> workspacesProvider = Provider<List<Workspace>>((
  Ref ref,
) {
  if (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock) {
    return <Workspace>[ref.watch(mockStoreProvider).dataset.workspace];
  }

  final List<String> ids =
      ref.watch(userProfileProvider).value?.workspaceIds ?? const <String>[];

  return <Workspace>[
    for (final String id in ids)
      if (ref.watch(liveWorkspaceProvider(id)).value case final Workspace w) w,
  ];
});

/// Whether there is anything to read from at all.
///
/// Mirrors the branching in every repository provider on purpose: mock mode
/// answers yes without a context, because the in-memory repositories never
/// look at one.
final Provider<bool> hasWorkspaceProvider = Provider<bool>((Ref ref) {
  if (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock) {
    return true;
  }

  return ref.watch(workspaceContextProvider) != null;
});

/// Keeps a business stream empty instead of exploding when there is no
/// workspace behind it.
///
/// **The app now renders its five tabs before anyone signs in** (hard rule 1),
/// and a signed-out visitor has no workspace — but the repository providers
/// *throw* on a null context rather than returning an empty repository, so the
/// check has to happen before the repository is read. Hence a wrapper around
/// the read rather than a null check after it.
///
/// The throw is still right for what it was written for: a signed-in seller
/// reaching a business screen with no workspace is a routing bug, and one that
/// should be loud. This only covers the state where having no workspace is the
/// expected answer.
final class WorkspaceGuard {
  static Stream<List<T>> listOrEmpty<T>(
    Ref ref,
    Stream<List<T>> Function() live,
  ) => ref.watch(hasWorkspaceProvider) ? live() : Stream<List<T>>.value(<T>[]);

  static Stream<T?> oneOrNull<T>(Ref ref, Stream<T?> Function() live) =>
      ref.watch(hasWorkspaceProvider) ? live() : Stream<T?>.value(null);
}

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
      StaleInventoryPolicy.defaultThreshold;
});

final Provider<List<Member>> workspaceMembersProvider = Provider<List<Member>>((
  Ref ref,
) {
  if (DevFlags.isDebugOrProfile && ref.watch(dataModeProvider).isMock) {
    return ref.watch(mockStoreProvider).dataset.members;
  }

  final String? id = ref.watch(currentWorkspaceIdProvider);

  if (id == null) return const <Member>[];

  return ref.watch(liveMembersProvider(id)).value ?? const <Member>[];
});

// See `itemProvider` for why a family's type is inferred rather than written.
// ignore: type_annotate_public_apis
final liveMembersProvider = StreamProvider.family<List<Member>, String>(
  (Ref ref, String workspaceId) =>
      ref.watch(workspaceRepositoryProvider).watchMembers(workspaceId),
);

/// The signed-in person's role in the workspace on screen, or null when it
/// cannot be told — signed out, or a demo with no account.
final Provider<MemberRole?> currentMemberRoleProvider = Provider<MemberRole?>((
  Ref ref,
) {
  final String? uid = ref.watch(currentUidProvider);

  if (uid == null) return null;

  final List<Member> members = ref.watch(workspaceMembersProvider);

  for (final Member member in members) {
    if (member.uid == uid) return member.role;
  }

  return null;
});

/// Whether to offer the controls that change the business itself.
///
/// **An affordance, never a permission.** `firestore.rules` decides who may
/// write (hard rule 11) and is unchanged by this; what this stops is drawing
/// a control that would always fail. A role that cannot be told reads as
/// allowed on purpose — the demo has no account at all, and hiding the
/// controls there would hide the feature from the only mode it can be
/// demonstrated in. A viewer who gets through anyway is refused by rules and
/// sees the message hard rule 6 allows.
final Provider<bool> canEditWorkspaceProvider = Provider<bool>((Ref ref) {
  final MemberRole? role = ref.watch(currentMemberRoleProvider);

  return role == null || role == MemberRole.owner || role == MemberRole.admin;
});
