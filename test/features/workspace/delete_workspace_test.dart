import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/pump_app.dart';

/// Who is offered the control that ends a business.
///
/// **The two affordance providers default opposite ways on purpose**, and
/// that is the whole point of this file: an unknown role reads as allowed for
/// editing (the demo has no account, and hiding the controls there would hide
/// the feature from the only mode it can be shown in) and as refused for
/// deleting, where the same reasoning would offer to destroy the demo's only
/// business with no account behind it to authorise the call.
///
/// Neither is a permission. `deleteWorkspace` checks the role server-side —
/// this only decides what is drawn.
void main() {
  ProviderContainer withRole(MemberRole? role) {
    final ProviderContainer container = ProviderContainer(
      overrides: [currentMemberRoleProvider.overrideWithValue(role)],
    );

    addTearDown(container.dispose);

    return container;
  }

  test('only an owner is offered the delete', () {
    expect(withRole(MemberRole.owner).read(canDeleteWorkspaceProvider), isTrue);
    expect(withRole(MemberRole.admin).read(canDeleteWorkspaceProvider), isFalse);
    expect(
      withRole(MemberRole.member).read(canDeleteWorkspaceProvider),
      isFalse,
    );
    expect(
      withRole(MemberRole.viewer).read(canDeleteWorkspaceProvider),
      isFalse,
    );
  });

  test('a role that cannot be told is a no', () {
    expect(withRole(null).read(canDeleteWorkspaceProvider), isFalse);
    // The same unknown role still draws the edit controls.
    expect(withRole(null).read(canEditWorkspaceProvider), isTrue);
  });

  test('the demo never offers it', () {
    final ProviderContainer container = mockContainer();

    // No account, so no membership document, so no owner to authorise it.
    expect(container.read(currentMemberRoleProvider), isNull);
    expect(container.read(canDeleteWorkspaceProvider), isFalse);
  });
}
