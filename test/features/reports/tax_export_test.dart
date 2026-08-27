import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/reports/presentation/controllers/report_controller.dart';
import 'package:reseller_studio/features/tax/providers.dart';

import '../../support/pump_app.dart';

/// The tax export is the only one scoped to a period, and the only one whose
/// rows are a form rather than a table of transactions.
void main() {
  test('every kind has a distinct file stem', () {
    final Set<String> stems = ReportKind.values
        .map((ReportKind kind) => kind.fileStem)
        .toSet();

    // Two kinds sharing a stem would overwrite each other in the share sheet.
    expect(stems, hasLength(ReportKind.values.length));
    expect(ReportKind.values, contains(ReportKind.tax));
  });

  test('the summary carries the year and the form lines', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    // Exercised through the provider the CSV reads, rather than the share
    // sheet: writing a file and opening a system sheet is not what is worth
    // pinning here.
    final String label = container.read(selectedTaxYearProvider).label;

    expect(label, isNotEmpty);
    expect(container.read(taxSummaryProvider).lines, isNotEmpty);
  });
}
