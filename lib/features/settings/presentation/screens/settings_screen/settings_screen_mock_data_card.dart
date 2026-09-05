part of 'settings_screen.dart';

/// The mock-data switch.
///
/// **Hidden entirely without dev mode** rather than shown disabled. A
/// greyed-out "use fake data" row in a shipped app is a support ticket at
/// best and a trust problem at worst. The check is duplicated from the
/// section that holds it because this card is what turns the fake business
/// on: one of the two guards being forgotten must not be enough.
class _MockDataCard extends ConsumerWidget {
  const _MockDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(devModeEnabledProvider)) return const SizedBox.shrink();

    final DataMode mode = ref.watch(dataModeProvider);

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SdIconV3(
                AppIconConstant.science,
                color: mode.isMock
                    ? context.sdTheme3.warning
                    : context.sdTheme3.textSecondary,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mock data',
                      style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      ),
                    ),
                    Text(
                      mode.isMock
                          ? 'Showing a seeded demo business.'
                          : 'Reading live data.',
                      style: context.textTheme3.bodySmall!.muted3(context),
                    ),
                  ],
                ),
              ),
              Switch(
                value: mode.isMock,
                onChanged: (bool _) =>
                    ref.read(dataModeProvider.notifier).toggle(),
              ),
            ],
          ),
          if (mode.isMock) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            const _MockSummary(),
          ],
        ],
      ),
    );
  }
}
