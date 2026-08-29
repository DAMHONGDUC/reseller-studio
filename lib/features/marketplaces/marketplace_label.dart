/// The words for a stored marketplace id.
///
/// **Not an ARB lookup**, unlike every other label in this app: a marketplace's
/// name is data the seller typed, not a string this app ships. Hard rule 7 is
/// about the app's own words.
///
/// **An unknown id falls back to itself.** An order placed on a marketplace
/// that has since been hard-deleted from another device must still render its
/// row rather than a blank — the same reason `CountryLabel` does it.
final class MarketplaceLabel {
  static String of(Map<String, String> names, String marketplaceId) =>
      names[marketplaceId] ?? marketplaceId;
}
