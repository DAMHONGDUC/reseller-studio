/// Riverpod wiring for `onboarding`. The router imports this file — never
/// anything under `onboarding/presentation/`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'onboarding_status.dart';
import 'presentation/controllers/onboarding_controller.dart';

export 'onboarding_status.dart';

/// Whether the intro flow still has to be shown. **What the router redirects
/// on**, alongside `isSignedInProvider` and `workspaceStatusProvider`.
final NotifierProvider<OnboardingController, OnboardingStatus>
onboardingStatusProvider =
    NotifierProvider<OnboardingController, OnboardingStatus>(
      OnboardingController.new,
    );
