/// Where a carrier's public tracking page lives.
///
/// **Only the carriers whose URL is known are here, and that is the point.**
/// A row that opens the wrong page is worse than one that does not open at
/// all: the seller reads "not found" and starts wondering whether the parcel
/// is lost. Anything absent from this map falls back to copying the number,
/// which works everywhere.
///
/// Keyed by the strings in `OrdersConstant.carriers` — the carrier field is
/// free text, so an unrecognised value is normal rather than a bug.
final class OrdersTrackingConstant {
  /// `{n}` is replaced by the tracking number, URL-encoded.
  static const Map<String, String> urlTemplates = <String, String>{
    'USPS': 'https://tools.usps.com/go/TrackConfirmAction?tLabels={n}',
    'UPS': 'https://www.ups.com/track?tracknum={n}',
    'FedEx': 'https://www.fedex.com/fedextrack/?trknbr={n}',
    'DHL': 'https://www.dhl.com/en/express/tracking.html?AWB={n}',
    'Royal Mail':
        'https://www.royalmail.com/track-your-item#/tracking-results/{n}',
    'Evri': 'https://www.evri.com/track/parcel/{n}',
  };

  /// The tracking page for [carrier], or null when there is nothing to open.
  ///
  /// Null for an unknown carrier, a blank number, and for `Other` — which is
  /// what a seller picks precisely when the app does not know the courier.
  static String? url({required String? carrier, required String? number}) {
    final String trimmed = number?.trim() ?? '';
    final String? template = carrier == null
        ? null
        : urlTemplates[carrier];

    if (template == null || trimmed.isEmpty) return null;

    return template.replaceAll('{n}', Uri.encodeComponent(trimmed));
  }
}
