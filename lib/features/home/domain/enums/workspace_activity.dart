/// Whether this business has anything in it yet.
///
/// **"Nothing needs your attention" and "you have not started" are different
/// claims**, and Home told a brand-new account the first one. A seller who has
/// added nothing is not clear — nobody has asked them for anything yet, and
/// saying otherwise is the section's own version of the zero hard rule 5
/// refuses to print for a figure it does not know.
enum WorkspaceActivity {
  /// A stream has not delivered yet. Home shows neither answer rather than
  /// flashing one at a returning seller before their records arrive.
  unknown,

  /// No items and no orders have ever existed here.
  untouched,

  /// There is a business to report on, whether or not anything is waiting.
  active,
}
