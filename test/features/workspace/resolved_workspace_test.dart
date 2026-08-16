import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/features/workspace/domain/entities/user_profile.dart';

/// **Switching business is a write to `lastWorkspaceId` and nothing else** —
/// there is no local "selected workspace" state anywhere in the app, because a
/// second copy of that answer is one a teammate's change could contradict.
///
/// That makes this getter the whole of the switcher's logic, so its edges are
/// worth pinning: a pointer at a business the seller was removed from must not
/// strand them on a workspace they can no longer read.
void main() {
  UserProfile profileWith({
    String? last,
    List<String> ids = const <String>[],
  }) => UserProfile(uid: 'u1', lastWorkspaceId: last, workspaceIds: ids);

  test('the last one used wins when it is still one of theirs', () {
    expect(
      profileWith(last: 'b', ids: <String>['a', 'b']).resolvedWorkspaceId,
      'b',
    );
  });

  test('a pointer at a business they have left falls back to the first', () {
    // Removed from 'b' by an owner while signed in elsewhere. Falling through
    // to the first they still belong to keeps the app readable; honouring the
    // stale pointer would open a workspace every rule denies them.
    expect(
      profileWith(last: 'b', ids: <String>['a']).resolvedWorkspaceId,
      'a',
    );
  });

  test('no pointer yet opens the first business', () {
    expect(profileWith(ids: <String>['a', 'b']).resolvedWorkspaceId, 'a');
  });

  test('belonging to nothing resolves to null, which is what forces setup', () {
    expect(profileWith(last: 'b').resolvedWorkspaceId, isNull);
  });
}
