import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/log_tag_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/barcode_camera_view.dart';

/// Scan a barcode and land on whatever it names (plan §7).
///
/// **One camera, one answer screen.** Whatever the code turns out to be — an
/// item, a location's label, or nothing — the result screen says so and
/// offers the next step; this screen only reads codes.
///
/// The camera itself is `BarcodeCameraView` — shared with Sourcing, which
/// asks a different question of the same code. Stopping on the first hit lives
/// there, which is why this screen can push a route without guarding against
/// being called thirty times a second.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final GlobalKey<BarcodeCameraViewState> _camera =
      GlobalKey<BarcodeCameraViewState>();

  /// Pushed rather than replacing this screen, so back is "scan the next one"
  /// — the camera pauses underneath and picks up again on return.
  Future<void> _onCode(String code) async {
    SdLogger.action(
      LogTagConstant.scanner,
      'Open scan result',
      <String, Object>{'length': code.length},
    );
    _camera.currentState?.pause();

    await context.push(AppRoutes.scanResult(code));

    if (!mounted) return;

    _camera.currentState?.resume();
  }

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    appBar: SdAppBarV3(title: context.l10n.scannerTitle),
    body: BarcodeCameraView(
      key: _camera,
      hint: context.l10n.scannerHint,
      onCode: _onCode,
    ),
  );
}
