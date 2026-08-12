part of 'settings_screen.dart';

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
        Text(
          value,
          style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ],
    ),
  );
}
