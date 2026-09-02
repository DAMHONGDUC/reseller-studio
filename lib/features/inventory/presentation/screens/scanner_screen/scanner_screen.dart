import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/barcode_camera_view.dart';
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

  void _onCode(String code) {
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
        icon: AppIconConstant.qrCodeScanner,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.scannerAddItem,
            isPrimary: true,
            onPressed: () => context.pushReplacement(AppRoutes.addItem),
          ),
          // The other reason a code matches nothing: the seller does not own
          // it yet and is deciding whether to. That decision is made standing
          // in the shop, so it belongs here rather than three levels down
          // under More — and the code goes with it, so the buy calculator
          // opens on what this business got for one last time.
          SdDialogActionV3(
            label: context.l10n.scannerEvaluate,
            onPressed: () =>
                context.pushReplacement(AppRoutes.evaluate(code: code)),
          ),
          SdDialogActionV3(
            label: context.l10n.scannerScanAgain,
            onPressed: () => _camera.currentState?.resume(),
          ),
        ],
      ),
    );
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
