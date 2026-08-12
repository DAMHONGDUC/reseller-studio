part of 'analytics_screen.dart';

class _StatementRow extends StatelessWidget {
  const _StatementRow({
    required this.label,
    required this.value,
    this.isDeduction = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isDeduction;
  final bool isTotal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            isDeduction ? '− $label' : label,
            style: isTotal
                ? context.textTheme3.bodyMedium!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  )
                : context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
        Text(
          value,
          style: context.textTheme3.bodyMedium!.tabular3.copyWith(
            color: isTotal
                ? context.sdTheme3.textPrimary
                : context.sdTheme3.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : null,
          ),
        ),
      ],
    ),
  );
}
