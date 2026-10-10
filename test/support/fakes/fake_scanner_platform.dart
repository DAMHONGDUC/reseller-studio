import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The camera, answered by the test: [scan] is a label held up to it, and
/// [calls] is every start and stop the scanner asked the platform for.
///
/// Installed as `MobileScannerPlatform.instance`, so the real `MobileScanner`
/// widget and controller run unchanged above it — only the hardware is fake.
class FakeScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture?> _barcodes =
      StreamController<BarcodeCapture?>.broadcast();

  /// `start`, `stop`, `torch` — in the order the scanner asked.
  final List<String> calls = <String>[];

  /// Thrown by the next `start` — a refused camera, say. Null starts it.
  MobileScannerException? startError;

  /// The frame the scanner last told the platform to read inside, as a share
  /// of the camera image.
  Rect? scanWindow;

  /// Swap this fake in for the test's duration.
  static FakeScannerPlatform install() {
    final MobileScannerPlatform previous = MobileScannerPlatform.instance;
    final FakeScannerPlatform fake = FakeScannerPlatform();

    MobileScannerPlatform.instance = fake;
    addTearDown(() => MobileScannerPlatform.instance = previous);

    return fake;
  }

  int get starts => calls.where((String call) => call == 'start').length;
  int get stops => calls.where((String call) => call == 'stop').length;

  /// A label in front of the lens.
  void scan(String code, {BarcodeFormat format = BarcodeFormat.ean13}) =>
      _barcodes.add(
        BarcodeCapture(
          barcodes: <Barcode>[Barcode(rawValue: code, format: format)],
        ),
      );

  /// A frame where the platform saw a code but could not read its value.
  void scanUnreadable() => _barcodes.add(
    const BarcodeCapture(barcodes: <Barcode>[Barcode(rawValue: '')]),
  );

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream<TorchState>.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream<double>.empty();

  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    calls.add('start');

    final MobileScannerException? error = startError;

    if (error != null) throw error;

    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      numberOfCameras: 2,
      size: Size(1080, 1920),
    );
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> toggleTorch() async => calls.add('torch');

  @override
  Future<void> updateScanWindow(Rect? window) async => scanWindow = window;

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> dispose() async {}
}
