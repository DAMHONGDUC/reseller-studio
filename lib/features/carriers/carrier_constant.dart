/// A carrier seeded into every new business.
class CarrierSeed {
  const CarrierSeed({required this.id, required this.name});

  final String id;
  final String name;
}

/// The editable carrier records a new business starts with.
final class CarrierConstant {
  static const List<CarrierSeed> defaults = <CarrierSeed>[
    CarrierSeed(id: 'usps', name: 'USPS'),
    CarrierSeed(id: 'ups', name: 'UPS'),
    CarrierSeed(id: 'fedex', name: 'FedEx'),
    CarrierSeed(id: 'dhl', name: 'DHL'),
    CarrierSeed(id: 'royal-mail', name: 'Royal Mail'),
  ];
}
