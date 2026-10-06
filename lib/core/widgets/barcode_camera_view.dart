import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../constants/log_tag_constant.dart';
import '../extensions/context_extensions.dart';
import '../permissions/app_permission.dart';
import '../providers/system_permissions_provider.dart';
import '../utils/scanner_frame_utils.dart';
import 'permission_settings_sheet.dart';

/// The camera, the codes it finds, and nothing about what they mean.
///
/// In `core/widgets/` because two features scan: Inventory looks a code up
/// against its shelves, Sourcing looks it up against what the seller has sold
/// before. **What differs is the answer, never the camera** — the format list,
/// the first-hit guard and the torch are the same job twice.
///
/// **It stops on the first hit.** Without that a single label produces dozens
/// of detections a second and the caller acts on all of them. [resume] is how
/// a caller that showed "no match" offers another go.
///
/// **It reads only inside the frame**, so a box with three codes on it gives
/// the one the seller lined up, not whichever the camera saw first.
class BarcodeCameraView extends ConsumerStatefulWidget {
  const BarcodeCameraView({
    required this.hint,
    required this.onCode,
    super.key,
  });

  /// One line over the camera saying what to point it at. A user-facing
  /// string, so the caller owns it (hard rule 7).
  final String hint;

  final ValueChanged<String> onCode;

  @override
  ConsumerState<BarcodeCameraView> createState() => BarcodeCameraViewState();
}

class BarcodeCameraViewState extends ConsumerState<BarcodeCameraView> {
  final MobileScannerController _controller = MobileScannerController(
    // One format set rather than "everything": retail barcodes and the QR
    // codes a seller prints for their own bins. Scanning every symbology
    // slows detection and finds codes on packaging nobody meant to scan.
    formats: const <BarcodeFormat>[
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );

  late final AppLifecycleListener _lifecycle;

  bool _handled = false;

  /// The Settings sheet is offered once per visit, not on every retry.
  bool _offeredSettings = false;

  /// Take codes again, after the caller has finished with the last one.
  void resume() => setState(() => _handled = false);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScannerState);
    // The scanner restarts itself on resume only when it already had the
    // camera, so a seller back from Settings would still see it refused.
    _lifecycle = AppLifecycleListener(onResume: _restartIfRefused);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.removeListener(_onScannerState);
    _disposeController();
    super.dispose();
  }

  /// `MobileScannerController.dispose` is async; `State.dispose` is not.
  /// Kicking it off without awaiting is the documented pattern, and the
  /// failure is logged rather than swallowed (hard rule 8).
  void _disposeController() {
    _controller.dispose().catchError((Object error, StackTrace stackTrace) {
      SdLogger.error(
        LogTagConstant.scanner,
        'Scanner failed to dispose',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  bool get _isRefused =>
      _controller.value.error?.errorCode ==
      MobileScannerErrorCode.permissionDenied;

  void _onScannerState() {
    if (_offeredSettings || !_isRefused) return;

    _offeredSettings = true;
    SdLogger.info(LogTagConstant.scanner, 'Camera permission refused');
    unawaited(_offerSettingsIfBlocked());
  }

  /// Opens the Settings sheet when the system will not ask again, and
  /// answers whether it did.
  Future<bool> _offerSettingsIfBlocked() async {
    final bool blocked = await ref
        .read(systemPermissionsProvider)
        .isBlocked(AppPermission.camera);

    if (!blocked || !mounted) return false;

    await PermissionSettingsSheet.show(
      context,
      permission: AppPermission.camera,
    );

    return true;
  }

  /// "Allow camera": the sheet when only Settings can help, otherwise ask
  /// again — Android shows the dialog a second time.
  Future<void> _allowCamera() async {
    SdLogger.action(LogTagConstant.scanner, 'Allow camera tapped');

    if (await _offerSettingsIfBlocked()) return;

    await _start();
  }

  void _restartIfRefused() {
    if (!_isRefused) return;

    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _controller.start();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.scanner,
        'Scanner failed to start',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final String? code = capture.barcodes
        .map((Barcode barcode) => barcode.rawValue)
        .firstWhere(
          (String? value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );

    if (_handled || code == null) return;

    _handled = true;
    SdLogger.action(LogTagConstant.scanner, 'Barcode scanned', <String, Object>{
      'length': code.length,
    });

    widget.onCode(code);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final Rect frame = ScannerFrameUtils.rect(constraints.biggest);

      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            scanWindow: frame,
            overlayBuilder: (BuildContext context, BoxConstraints _) =>
                ScanWindowOverlay(
                  controller: _controller,
                  scanWindow: frame,
                  color: context.sdTheme3.barrier,
                  borderColor: context.colorScheme3.primary,
                  borderWidth: SdSpacingConstant.w2,
                  borderRadius: BorderRadius.circular(SdRadiusV3.card),
                ),
            errorBuilder:
                (BuildContext context, MobileScannerException error) =>
                    _CameraUnavailable(
                      refused:
                          error.errorCode ==
                          MobileScannerErrorCode.permissionDenied,
                      onAllow: _allowCamera,
                    ),
          ),
          _CameraChrome(controller: _controller, hint: widget.hint),
        ],
      );
    },
  );
}

/// The torch, the camera switch and the hint — hidden while the camera is
/// down, so they never sit on top of the message saying why.
class _CameraChrome extends StatelessWidget {
  const _CameraChrome({required this.controller, required this.hint});

  final MobileScannerController controller;
  final String hint;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<MobileScannerState>(
        valueListenable: controller,
        builder:
            (BuildContext context, MobileScannerState state, Widget? child) =>
                state.error == null ? child! : const SizedBox.shrink(),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: SdSpacingConstant.h12,
              right: SdContentPaddingV3.horizontal,
              child: Column(
                children: <Widget>[
                  _CameraButton(
                    icon: AppIconConstant.flashlightOn,
                    tooltip: context.l10n.scannerTorch,
                    onPressed: controller.toggleTorch,
                  ),
                  SizedBox(height: SdSpacingConstant.h8),
                  _CameraButton(
                    icon: AppIconConstant.cameraswitch,
                    tooltip: context.l10n.scannerSwitchCamera,
                    onPressed: controller.switchCamera,
                  ),
                ],
              ),
            ),
            Positioned(
              left: SdContentPaddingV3.horizontal,
              right: SdContentPaddingV3.horizontal,
              bottom: SdContentPaddingV3.bottom(context),
              child: SdCardV3(
                layer: SdCardLayerV3.elevated,
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: context.textTheme3.bodyMedium!.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// What replaces the feed when the camera cannot start.
class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.refused, required this.onAllow});

  /// The seller said no, as opposed to the camera failing on its own.
  final bool refused;

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.sdTheme3.background,
    child: refused
        ? SdEmptyStateV3(
            icon: AppPermission.camera.blockedIcon,
            title: AppPermission.camera.blockedTitle(context),
            message: AppPermission.camera.blockedMessage(context),
            action: SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.scannerAllowCamera,
              onPressed: onAllow,
            ),
          )
        : SdEmptyStateV3(
            icon: AppIconConstant.noPhotography,
            title: context.l10n.errorGenericTitle,
          ),
  );
}

/// A control that has to read over a camera feed, so it carries its own
/// surface rather than relying on the page behind it.
class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: context.sdTheme3.surfaceElevated,
    shape: const CircleBorder(),
    // The app bar action's glyph, because this is chrome too — a control over
    // a camera feed is the last one that may be small.
    child: IconButton(
      icon: SdIconV3(
        icon,
        size: SdAppBarActionButtonV3.glyphSize,
        color: context.sdTheme3.textPrimary,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}
