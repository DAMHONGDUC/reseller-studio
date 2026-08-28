# Carriers

Read this file before changing anything in `lib/features/carriers/` or the
shipment carrier picker.

## Business-owned carrier records

- **A carrier is a record the business owns, not a fixed picker list.**
  Owner's rule. Sellers must be able to add, rename, and remove local couriers;
  More exposes that management workflow as a direct destination and shipment
  forms consume it. Do not bury Carrier management inside Settings: shipping
  configuration is part of operating the business, not an app preference.
- **Carrier removal is soft-delete.** Orders retain the carrier name they were
  shipped with, and a deleted carrier disappears only from future choices.
- **Every new business starts with USPS, UPS, FedEx, DHL, and Royal Mail.**
  These cover the app's launch jurisdictions and remain ordinary editable
  records rather than protected system values.
