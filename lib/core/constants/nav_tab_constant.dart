/// The five bottom tabs, in the order the router declares its branches.
///
/// These are **analytics identifiers, not labels**. They are never localized
/// and never renamed once shipped: a name that changes splits one tab into two
/// series in the dashboard and silently ends the old one.
///
/// The list is closed — hard rule 13. Adding a tab is a product decision, and
/// it changes this file, `AppShell`'s destinations and the router's branches
/// together.
final class NavTabConstant {
  /// Index-aligned with `AppShell`'s destinations and the shell's branches.
  static const List<String> analyticsNames = <String>[
    'home',
    'inventory',
    'orders',
    'analytics',
    'more',
  ];

  /// The identifier for a branch index, or `null` if the index is outside the
  /// five — which can only mean the two lists have drifted apart.
  static String? nameAt(int index) =>
      index >= 0 && index < analyticsNames.length
      ? analyticsNames[index]
      : null;
}
