part of 'settings_screen.dart';

/// The mock-data switch.
///
/// **Hidden entirely in a release build** rather than shown disabled. A
/// greyed-out "use fake data" row in a shipped app is a support ticket at
/// best and a trust problem at worst; `DevFlags.isDebugOrProfile` is a
/// compile-time constant, so this whole subtree is tree-shaken out.
class _MockDataCard extends ConsumerWidget {
  const _MockDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DevFlags.isDebugOrProfile) return const SizedBox.shrink();

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
