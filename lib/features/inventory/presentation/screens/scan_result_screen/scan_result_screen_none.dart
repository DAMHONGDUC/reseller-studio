part of 'scan_result_screen.dart';

/// A code nothing has. Usually the seller is holding something to add — or
/// standing in a shop deciding whether to buy it, so the code goes to the buy
/// calculator as well.
class _NoMatchResult extends StatelessWidget {
  const _NoMatchResult({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => AppSection.rows(
    title: context.l10n.scanResultActions,
    subtitle: context.l10n.scannerNoMatchBody,
    children: <Widget>[
      AppListRow(
        icon: AppIconConstant.add,
        title: context.l10n.scannerAddItem,
        onTap: () => context.push(AppRoutes.addItemWithCode(code: code)),
      ),
      AppListRow(
        icon: AppIconConstant.calculate,
        title: context.l10n.scannerEvaluate,
        onTap: () => context.push(AppRoutes.evaluate(code: code)),
      ),
    ],
  );
}
