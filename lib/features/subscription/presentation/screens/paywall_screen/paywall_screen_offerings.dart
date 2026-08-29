part of 'paywall_screen.dart';

class _PaywallOfferings extends ConsumerStatefulWidget {
  const _PaywallOfferings({required this.isBusy});

  final bool isBusy;

  @override
  ConsumerState<_PaywallOfferings> createState() => _PaywallOfferingsState();
}

class _PaywallOfferingsState extends ConsumerState<_PaywallOfferings> {
  List<PlanOffering> _offerings = const <PlanOffering>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

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
      // Already logged by SubscriptionController.
      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SdLoadingV3();

    return _PaywallPlanCard(offerings: _offerings, isBusy: widget.isBusy);
  }
}
