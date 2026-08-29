import 'package:flutter/widgets.dart';

import '../../features/tax/domain/enums/tax_jurisdiction.dart';
import '../extensions/context_extensions.dart';

/// The word for a distance unit, and the number behind it.
///
/// In `core/` because two features need it from opposite directions: `tax`
/// reports the year's distance, `expenses` collects one trip's. `domain/`
/// holds no strings (hard rule 7), so the enum carries the concept and this
/// carries the words.
final class MileageUnitLabel {
  const MileageUnitLabel._();

  /// "Miles" / "Kilometres" — a noun, for a field label or a unit suffix.
  static String of(BuildContext context, MileageUnit unit) => switch (unit) {
    MileageUnit.mile => context.l10n.mileageUnitMiles,
    MileageUnit.kilometre => context.l10n.mileageUnitKilometres,
  };

  /// A distance as a seller wrote it: no decimals when it has none.
  ///
  /// `12` rather than `12.0`, because a trip is not measured to a tenth of a
  /// mile and a trailing zero reads like precision nobody has.
  static String distance(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
