import 'package:flutter/widgets.dart';

import '../extensions/context_extensions.dart';
import 'app_failure.dart';
import 'failure_mapper.dart';

/// The one place a failure becomes a sentence a seller reads.
///
/// **`AppFailure.technicalMessage` never reaches a widget** (hard rule 6) —
/// it carries the original exception's text, which is exactly the raw error
/// the plan forbids showing. Every screen that catches something calls
/// [message] and shows what comes back.
///
/// An unrecognised throw maps to the generic line rather than its
/// `toString()`, so a screen cannot leak one by forgetting.
final class FailurePresenter {
  /// What to show the user for [error], whatever it turned out to be.
  static String message(BuildContext context, Object error) {
    final AppFailure failure = FailureMapper.map(error);

    return switch (failure.kind) {
      AppFailureKind.offline => context.l10n.errorOfflineMessage,
      AppFailureKind.unauthenticated => context.l10n.errorSignedOutMessage,
      AppFailureKind.permissionDenied => context.l10n.errorNoAccessMessage,
      AppFailureKind.notFound => context.l10n.errorNotFoundMessage,
      AppFailureKind.invalidData => context.l10n.errorInvalidDataMessage,
      AppFailureKind.limitReached => context.l10n.errorLimitReachedMessage,
      AppFailureKind.unknown => context.l10n.errorGenericMessage,
    };
  }
}
