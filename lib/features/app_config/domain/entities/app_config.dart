/// One switch board for the whole product, not for one business.
///
/// **It is not a workspace record** (hard rule 14 governs those): nothing here
/// belongs to a seller, and two businesses on the same build read the same
/// answer. It is the owner's remote switch, read by every client and written
/// by nobody in the app.
class AppConfig {
  const AppConfig({required this.premiumEnabled});

  /// What a client falls back to.
  ///
  /// **Monetisation ON, and the direction is deliberate.** A failed read, a
  /// cold start with no signal, a document nobody has created yet: every one
  /// of them lands here, and defaulting the other way would hand the paid
  /// half of the app to everyone the first time Firestore is slow. Same
  /// argument as `currentPlanProvider` falling back to Free.
  static const AppConfig fallback = AppConfig(premiumEnabled: true);

  /// Whether the plan system applies at all.
  ///
  /// False turns monetisation off for **everyone**: no ceiling blocks a
  /// create, every capability is included, and nothing offers a purchase. It
  /// is one flag rather than a per-feature list because half-priced is not a
  /// state this product has.
  final bool premiumEnabled;

  Map<String, Object?> toLogData() => <String, Object?>{
    'premiumEnabled': premiumEnabled,
  };
}
