/// A three-state answer to "does this record carry that field at all?".
///
/// Photos, a recorded cost, a tracking number, a payout: every one of them is
/// the same question, and one enum is what stops five filter groups inventing
/// five slightly different ways to ask it.
///
/// **[absent] is a filter, never a claim about the value.** An item with no
/// cost has an unknown cost, not a cost of zero — hard rule 4 — so this asks
/// whether the field was filled in and nothing more.
///
/// The words on the chips stay at the call site: "With photos" and "Has
/// tracking" are the same three states and must not read as one generic
/// "Yes".
enum PresenceFilter {
  any,
  present,
  absent;

  /// Whether a record whose field is [hasValue] belongs under this filter.
  bool matches(bool hasValue) => switch (this) {
    PresenceFilter.any => true,
    PresenceFilter.present => hasValue,
    PresenceFilter.absent => !hasValue,
  };

  /// Whether this narrows anything — what an applied-filter count counts.
  bool get isActive => this != PresenceFilter.any;
}
