import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import 'barcode_camera_view.dart';

/// Scan one code and hand it back.
///
/// **A pushed page rather than a route in `AppRoutes`.** A go_router path is a
/// destination somebody can deep-link to and land on; this is a question the
/// caller asked and is waiting for the answer to, which is what returning a
/// value means. A deep link into it would arrive with nobody listening.
///
/// The screen a code *navigates* to is `ScannerScreen`, which is a
/// destination and does have a path. Both draw the same
/// [BarcodeCameraView] — what differs is who answers the code.
class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({
    required this.title,
    required this.hint,
    super.key,
  });

  final String title;
  final String hint;

  /// Opens the camera and completes with the code, or null if the seller
  /// backed out.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String hint,
  }) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (BuildContext context) =>
          BarcodeScannerPage(title: title, hint: hint),
    ),
  );

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    appBar: SdAppBarV3(title: title),
    body: BarcodeCameraView(
      hint: hint,
      onCode: (String code) => Navigator.of(context).pop(code),
    ),
  );
}
