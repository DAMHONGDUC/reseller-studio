import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../constants/log_tag_constant.dart';
import '../extensions/context_extensions.dart';

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
class BarcodeCameraView extends StatefulWidget {
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
  State<BarcodeCameraView> createState() => BarcodeCameraViewState();
}

class BarcodeCameraViewState extends State<BarcodeCameraView> {
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

  bool _handled = false;

  /// Take codes again, after the caller has finished with the last one.
  void resume() => setState(() => _handled = false);

  @override
  void dispose() {
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
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      MobileScanner(controller: _controller, onDetect: _onDetect),
      Positioned(
        top: SdSpacingConstant.h12,
        right: SdContentPaddingV3.horizontal,
        child: Column(
          children: <Widget>[
            _CameraButton(
              icon: AppIconConstant.flashlightOn,
              tooltip: context.l10n.scannerTorch,
              onPressed: _controller.toggleTorch,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            _CameraButton(
              icon: AppIconConstant.cameraswitch,
              tooltip: context.l10n.scannerSwitchCamera,
              onPressed: _controller.switchCamera,
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
            widget.hint,
            textAlign: TextAlign.center,
            style: context.textTheme3.bodyMedium!.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ),
      ),
    ],
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
    child: IconButton(
      icon: SdIconV3(icon, color: context.sdTheme3.textPrimary),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}
