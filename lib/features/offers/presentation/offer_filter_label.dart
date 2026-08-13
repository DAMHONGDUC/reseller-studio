import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../providers.dart';

/// The words on the Offers filter chips. The enum itself holds none, because
/// `providers.dart` has no `BuildContext` to read a translation with.
final class OfferFilterLabel {
  static String of(BuildContext context, OfferFilter filter) =>
      switch (filter) {
        OfferFilter.pending => context.l10n.offerFilterPending,
        OfferFilter.accepted => context.l10n.offerFilterAccepted,
        OfferFilter.declined => context.l10n.offerFilterDeclined,
        OfferFilter.expired => context.l10n.offerFilterExpired,
      };
}
