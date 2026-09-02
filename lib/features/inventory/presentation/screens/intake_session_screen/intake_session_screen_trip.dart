part of 'intake_session_screen.dart';

/// Where the trip was and when — asked once for the whole session.
///
/// Both are optional (hard rule 2). Asking them once is the entire saving:
/// per item they are two extra taps thirty times over, which is why in
/// practice they were never filled in at all.
class _TripHeader extends ConsumerWidget {
  const _TripHeader({required this.state});

  final IntakeSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Source> sources =
        ref.watch(sourcesProvider).value ?? const <Source>[];
    final DateTime now = DateTime.now();

    return SdCardV3(
      child: Column(
        children: <Widget>[
          PickerField(
            label: context.l10n.commonSource,
            value: sources
                .where((Source source) => source.id == state.sourceId)
                .map((Source source) => source.name)
                .firstOrNull,
            icon: AppIconConstant.storefront,
            onTap: () async {
              final Source? picked = await OptionPickerSheet.show<Source>(
                context,
                title: context.l10n.commonSource,
                selected: sources
                    .where((Source source) => source.id == state.sourceId)
                    .firstOrNull,
                options: sources
                    .map(
                      (Source source) => PickerOption<Source>(
                        value: source,
                        label: source.name,
                      ),
                    )
                    .toList(),
              );

              if (picked == null) return;

              ref
                  .read(intakeSessionControllerProvider.notifier)
                  .selectSource(picked.id);
            },
          ),
          SizedBox(height: SdSpacingConstant.h12),
          PickerField(
            label: context.l10n.commonDate,
            value: DateTimeUtils.mediumDate(
              state.purchaseDate,
              locale: context.localeTag,
            ),
            icon: AppIconConstant.calendarMonth,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: state.purchaseDate,
                firstDate: DateTime(
                  now.year - DatePickerConstant.recentEntryYearsBack,
                ),
                lastDate: now,
              );

              if (picked == null) return;

              ref
                  .read(intakeSessionControllerProvider.notifier)
                  .selectDate(picked);
            },
          ),
        ],
      ),
    );
  }
}
