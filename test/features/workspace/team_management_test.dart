import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:seller_os/core/widgets/app_add_fab_scaffold.dart';
import 'package:seller_os/features/auth/providers.dart';
import 'package:seller_os/features/listings/domain/enums/listing_status.dart';
import 'package:seller_os/features/workspace/domain/entities/pending_invite.dart';
import 'package:seller_os/features/workspace/domain/repositories/team_repository.dart';
import 'package:seller_os/features/workspace/presentation/screens/team_screen/team_screen.dart';
import 'package:seller_os/features/workspace/presentation/widgets/invite_member_sheet.dart';
import 'package:seller_os/features/workspace/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Team management (plan §24).
///
/// **Nothing here is a permission** — `firestore.rules` and the three
/// callables are. What these pin is the affordance: hard rule 11 says nobody
/// edits their own membership, so the one row that must never be a control is
/// your own.
class _FakeTeamRepository implements TeamRepository {
  @override
  Stream<List<PendingInvite>> watchMyInvites(String email) =>
      Stream<List<PendingInvite>>.value(const <PendingInvite>[]);

  @override
  Future<String> invite({
    required String workspaceId,
    required String email,
    required MemberRole role,
  }) async => 'inv-1';

  @override
  Future<String> acceptInvite(String inviteId) async => 'ws-1';

  @override
  Future<void> removeMember({
    required String workspaceId,
    required String memberUid,
  }) async {}

  @override
  Future<void> changeRole({
    required String workspaceId,
    required String memberUid,
    required MemberRole role,
  }) async {}
}

void main() {
  /// The demo's owner uid, so "your own row" is a row the test can name.
  const String ownerUid = 'dev-bypass-user';

  List<Override> managing({String uid = ownerUid}) => <Override>[
    teamRepositoryProvider.overrideWithValue(_FakeTeamRepository()),
    currentUidProvider.overrideWithValue(uid),
  ];

  testWidgets('an owner is offered the invite button', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const TeamScreen(), overrides: managing());

    expect(find.text('Invite a teammate'), findsOneWidget);
  });

  testWidgets('the demo offers nothing to invite with', (
    WidgetTester tester,
  ) async {
    // No account and no backend: a button that could only fail is worse than
    // none. `teamRepositoryProvider` is null in mock mode by design.
    await pumpScreen(tester, const TeamScreen());

    expect(
      tester.widget<AppAddFabScaffold>(find.byType(AppAddFabScaffold)).showAdd,
      isFalse,
    );
  });

  testWidgets('your own row opens nothing, a teammate\'s does', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const TeamScreen(), overrides: managing());

    // Hard rule 11: nobody edits their own membership document, and the rules
    // refuse it whatever the UI offers.
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    expect(find.byType(SdBottomSheetV3), findsNothing);

    await tester.tap(find.text('Sam Rivera'));
    await tester.pumpAndSettle();

    expect(find.text('Change role'), findsOneWidget);
    expect(find.text('Remove from business'), findsOneWidget);
  });

  test('an invitation never grants ownership', () {
    // `inviteMember` refuses `owner` server-side; offering it in the picker
    // would be a control whose only outcome is an error.
    expect(
      InviteMemberSheet.invitableRoles,
      isNot(contains(MemberRole.owner)),
    );
  });

  testWidgets('a role describes itself from what it may actually do', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const TeamScreen(), overrides: managing());

    // Read off `canOwn` / `canAdminister` / `canWrite` rather than written per
    // case, so a role whose powers change cannot keep the old sentence.
    expect(find.textContaining('deleting the business'), findsOneWidget);
    expect(find.textContaining('change nothing'), findsOneWidget);
  });
}
