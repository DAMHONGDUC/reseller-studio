import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/storage_location.dart';
import '../../../providers.dart';

/// Scan a barcode and land on whatever it names (plan §7).
///
/// **One camera, three answers.** A code either matches an item's barcode or
/// SKU, a location's label, or nothing — and the third case is the useful one:
/// a seller scanning an unknown code is usually holding something they are
/// about to add, so it offers to start an item with the code already filled
/// in rather than saying "not found" and stopping.
///
/// The scanner stops on the first hit. Without that a single label produces
/// dozens of detections a second and the app pushes the same route dozens of
/// times.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
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

  /// Set once a code has been acted on, so the stream of further detections
  /// for the same label is ignored.
  bool _handled = false;

  @override
  void dispose() {
    unawaitedDispose();
    super.dispose();
  }

  /// `MobileScannerController.dispose` is async; `State.dispose` is not.
  /// Kicking it off without awaiting is the documented pattern, and the
  /// failure is logged rather than swallowed (hard rule 8).
  void unawaitedDispose() {
    _controller.dispose().catchError((Object error, StackTrace stackTrace) {
      AppLogger.error(
        'Scanner failed to dispose',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final String? code = capture.barcodes
        .map((Barcode barcode) => barcode.rawValue)
        .firstWhere((String? value) => value != null && value.isNotEmpty,
            orElse: () => null);

    if (_handled || code == null) return;

    _handled = true;
    AppLogger.action('Barcode scanned', <String, Object>{
      'length': code.length,
    });

    final Item? item = _findItem(code);

    if (item != null) {
      context.pushReplacement(AppRoutes.item(item.id));

      return;
    }

    final StorageLocation? location = _findLocation(code);

    if (location != null) {
      SdSnackBarUtilsV3.info(
        context,
        context.l10n.scannerFoundLocation(location.name),
      );
      context.pop();

      return;
    }

    _offerToAdd(code);
  }

  /// Barcode first, then SKU. A seller who typed the SKU into the barcode box
  /// — or the other way round — still finds their item.
  Item? _findItem(String code) {
    final List<Item> items = ref.read(itemsProvider).value ?? const <Item>[];

    for (final Item item in items) {
      if (item.barcode == code || item.sku == code) return item;
    }

    return null;
  }

  StorageLocation? _findLocation(String code) {
    final List<StorageLocation> locations =
        ref.read(locationsProvider).value ?? const <StorageLocation>[];

    for (final StorageLocation location in locations) {
      if (location.barcode == code) return location;
    }

    return null;
  }

  Future<void> _offerToAdd(String code) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.scannerNoMatchTitle,
        message: context.l10n.scannerNoMatchBody,
        icon: Symbols.qr_code_scanner_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.scannerAddItem,
            isPrimary: true,
            onPressed: () => context.pushReplacement(AppRoutes.addItem),
          ),
          SdDialogActionV3(
            label: context.l10n.scannerScanAgain,
            onPressed: () => setState(() => _handled = false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    appBar: SdAppBarV3(
      title: context.l10n.scannerTitle,
      actions: <Widget>[
        IconButton(
          icon: const SdIconV3(Symbols.flashlight_on_rounded),
          tooltip: context.l10n.scannerTorch,
          onPressed: () => _controller.toggleTorch(),
        ),
        IconButton(
          icon: const SdIconV3(Symbols.cameraswitch_rounded),
          tooltip: context.l10n.scannerSwitchCamera,
          onPressed: () => _controller.switchCamera(),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Positioned(
          left: SdContentPaddingV3.horizontal,
          right: SdContentPaddingV3.horizontal,
          bottom: SdContentPaddingV3.bottom(context),
          child: SdCardV3(
            layer: SdCardLayerV3.elevated,
            child: Text(
              context.l10n.scannerHint,
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
