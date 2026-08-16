import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../onboarding_page.dart';
import '../../../onboarding_page_content.dart';
import '../../../providers.dart';

part 'onboarding_screen_actions.dart';
part 'onboarding_screen_dots.dart';
part 'onboarding_screen_page.dart';

/// The intro flow — the first thing a new install shows, and the only screen
/// that comes before the sign-in gate.
///
/// **It does not weaken hard rule 1.** Login is still mandatory and there is
/// still no guest mode: nothing here reads or writes a business record, and
/// the only way out of it is the login screen. It is a description of the
/// product, not a way into it.
///
/// **It navigates nowhere.** Finishing sets the flag on
/// `onboardingStatusProvider` and the router's redirect moves the seller on by
/// itself — the same contract every other pre-Home screen keeps, so there is
/// one place that decides where a person lands.
///
/// Shown once per install (`PrefsKeyConstant.onboardingSeen`). Skipping counts
/// as finishing: a seller who does not want the tour should not be asked twice.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();

  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Marks the intro done, whether it was read or skipped.
  Future<void> _finish() =>
      ref.read(onboardingStatusProvider.notifier).complete();

  Future<void> _next(int total) {
    if (_index >= total - 1) return _finish();

    return _pages.nextPage(
      duration: SdMotionV3.normal,
      curve: SdMotionV3.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<OnboardingPage> pages = OnboardingPageContent.of(context);
    final bool isLast = _index == pages.length - 1;

    return SdScaffoldV3(
      // `bottom: false` — the pinned action carries the device inset itself,
      // and a SafeArea here would add the home indicator a second time.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _SkipRow(visible: !isLast, onSkip: _finish),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: pages.length,
                onPageChanged: (int index) => setState(() => _index = index),
                itemBuilder: (BuildContext context, int index) =>
                    _OnboardingPageView(page: pages[index]),
              ),
            ),
            _OnboardingDots(count: pages.length, index: _index),
            _PinnedNextAction(
              isLast: isLast,
              onPressed: () => _next(pages.length),
            ),
          ],
        ),
      ),
    );
  }
}
