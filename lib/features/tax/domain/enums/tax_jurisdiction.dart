/// Which country's rules a workspace files under (plan §20).
///
/// **Two ship, and a third is data rather than a branch** — `CLAUDE.md` names
/// the US and the UK as the launch markets, and §20 requires the rules stay
/// country-specific and configurable. Everything that differs between them
/// hangs off this value: the tax year, the category list, the mileage rate.
/// An `if (isUk)` anywhere outside this feature's `domain/` is the bug the
/// rule exists to stop.
enum TaxJurisdiction {
  us,
  uk;

  /// The month and day the tax year opens.
  ///
  /// The US year is the calendar year; the UK's runs 6 April to 5 April. That
  /// single fact is why nothing here may write `DateTime(year, 1, 1)`.
  int get yearStartMonth => switch (this) {
    TaxJurisdiction.us => DateTime.january,
    TaxJurisdiction.uk => DateTime.april,
  };

  int get yearStartDay => switch (this) {
    TaxJurisdiction.us => 1,
    TaxJurisdiction.uk => 6,
  };

  /// Whether a tax year spans two calendar years, and therefore whether it is
  /// named "2026" or "2026/27".
  bool get yearSpansTwoCalendarYears => this != TaxJurisdiction.us;

  /// The distance unit the mileage rate is set in. Both authorities use
  /// statute miles, but it is stated rather than assumed — a jurisdiction
  /// added in kilometres would otherwise silently deduct the wrong figure.
  MileageUnit get mileageUnit => MileageUnit.mile;

  /// Parsed from the workspace's stored country code, falling back to the US.
  ///
  /// A fallback rather than a throw: a workspace created before this feature
  /// existed has a country this cannot match, and refusing to open the screen
  /// would be worse than showing a jurisdiction the seller can change.
  static TaxJurisdiction fromCountryCode(String code) =>
      switch (code.toUpperCase()) {
        'GB' || 'UK' => TaxJurisdiction.uk,
        _ => TaxJurisdiction.us,
      };
}

enum MileageUnit { mile, kilometre }
