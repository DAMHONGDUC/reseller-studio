part of 'subscription_screen.dart';

/// The three tiers, priced.
///
/// **Loaded once into local state rather than watched.** Offerings come from
/// the store over the network and never change while a screen is open, so a
/// provider that refetched on every rebuild would put a round trip behind
/// each frame.
class _Offerings extends ConsumerStatefulWidget {
  const _Offerings({required this.currentPlan, required this.isBusy});

  final SellerPlan currentPlan;
  final bool isBusy;

  @override
  ConsumerState<_Offerings> createState() => _OfferingsState();
}

class _OfferingsState extends ConsumerState<_Offerings> {
  List<PlanOffering> _offerings = const <PlanOffering>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// A failure here is not worth a message: the cards still render what each
  /// plan includes, which is most of the screen. The controller logged it.
  Future<void> _load() async {
    try {
      final List<PlanOffering> offerings = await ref
          .read(subscriptionControllerProvider.notifier)
          .loadOfferings();

      if (!mounted) return;

      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SdLoadingV3();

    return Column(
      children: <Widget>[
        for (final SellerPlan plan in SellerPlan.values)
          Padding(
            padding: EdgeInsets.only(bottom: SdContentPaddingV3.listItemGap),
            child: _PlanCard(
              plan: plan,
              currentPlan: widget.currentPlan,
              offerings: _offerings
                  .where((PlanOffering offering) => offering.plan == plan)
                  .toList(),
              isBusy: widget.isBusy,
            ),
          ),
      ],
    );
  }
}
