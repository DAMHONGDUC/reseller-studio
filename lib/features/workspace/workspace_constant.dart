/// A country or currency a workspace can be created in.
///
/// Public because [WorkspaceConstant] exposes the lists, and a constants class
/// that hands back a private type is one nobody outside the file can read.
class WorkspaceOption {
  const WorkspaceOption({required this.code, required this.label});

  /// ISO 3166 alpha-2 for a country, ISO 4217 for a currency.
  final String code;

  final String label;
}

/// The countries, currencies and business types offered at workspace setup.
///
/// **A short list, not every ISO code.** Onboarding is the one screen a seller
/// has no reason to trust yet, and a 180-row picker is where they stop. The
/// full list belongs behind a search box in Settings when someone asks for it.
///
/// The currency a workspace is created with is the default every money field
/// inherits, and **changing it later does not convert existing records** —
/// nobody knows what rate applied to a purchase made last March.
final class WorkspaceConstant {
  static const List<WorkspaceOption> currencies = <WorkspaceOption>[
    WorkspaceOption(code: 'USD', label: 'US Dollar (\$)'),
    WorkspaceOption(code: 'EUR', label: 'Euro (€)'),
    WorkspaceOption(code: 'GBP', label: 'British Pound (£)'),
    WorkspaceOption(code: 'VND', label: 'Vietnamese Dong (₫)'),
    WorkspaceOption(code: 'AUD', label: 'Australian Dollar'),
    WorkspaceOption(code: 'CAD', label: 'Canadian Dollar'),
    WorkspaceOption(code: 'JPY', label: 'Japanese Yen (¥)'),
    WorkspaceOption(code: 'SGD', label: 'Singapore Dollar'),
  ];

  static const List<WorkspaceOption> countries = <WorkspaceOption>[
    WorkspaceOption(code: 'US', label: 'United States'),
    WorkspaceOption(code: 'GB', label: 'United Kingdom'),
    WorkspaceOption(code: 'VN', label: 'Vietnam'),
    WorkspaceOption(code: 'AU', label: 'Australia'),
    WorkspaceOption(code: 'CA', label: 'Canada'),
    WorkspaceOption(code: 'DE', label: 'Germany'),
    WorkspaceOption(code: 'FR', label: 'France'),
    WorkspaceOption(code: 'JP', label: 'Japan'),
    WorkspaceOption(code: 'SG', label: 'Singapore'),
  ];

  /// Optional at creation (plan §28) — it drives nothing today and exists so
  /// the tax work later has something to branch on.
  static const List<String> businessTypes = <String>[
    'Sole trader',
    'Partnership',
    'Limited company',
    'Hobby seller',
  ];

  /// The label for a code, or the code itself when it is not in the list —
  /// a workspace created on a build with a longer list must still render.
  static String labelFor(List<WorkspaceOption> options, String code) {
    for (final WorkspaceOption option in options) {
      if (option.code == code) return option.label;
    }

    return code;
  }
}
