import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../logging/app_logger.dart';

/// Renders a stored photo, whichever kind of URL it turned out to be.
///
/// **The app has two** — an https download URL in live mode, and a local file
/// path in mock mode, because there is no bucket to upload to before Firebase
/// exists. Every photo in the app goes through here rather than
/// `Image.network`, so mock mode shows the picture a seller just took instead
/// of a broken-image box.
///
/// A failed load renders the same placeholder as no photo at all: a grey well
/// is a better answer than a red X, and the failure is logged rather than
/// shown (hard rule 6).
class AppPhoto extends StatelessWidget {
  const AppPhoto({
    required this.url,
    required this.size,
    this.borderRadius,
    super.key,
  });

  final String? url;
  final double size;
  final BorderRadius? borderRadius;

  /// True for anything the network stack should fetch. Everything else is
  /// treated as a path on this device.
  static bool isRemote(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final String? source = url;
    final BorderRadius radius = borderRadius ?? SdRadiusV3.thumbnailAll;

    if (source == null || source.isEmpty) {
      return _PhotoPlaceholder(size: size, borderRadius: radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: isRemote(source)
          ? Image.network(
              source,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? s) =>
                      _onError(context, error, s, radius),
            )
          : Image.file(
              File(source),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? s) =>
                      _onError(context, error, s, radius),
            ),
    );
  }

  /// Logs, then falls back to the placeholder. A caught failure nobody logs
  /// is a failure nobody can fix (hard rule 8).
  Widget _onError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    BorderRadius radius,
  ) {
    AppLogger.error(
      'Could not load photo',
      error: error,
      stackTrace: stackTrace,
      data: <String, Object>{'isRemote': isRemote(url ?? '')},
    );

    return _PhotoPlaceholder(size: size, borderRadius: radius);
  }
}

/// The well shown when there is no photo, or it would not load.
///
/// A placeholder rather than nothing: without it, rows with photos and rows
/// without would have different heights and the list would look broken.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.size, required this.borderRadius});

  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.sdTheme3.surfaceSunken,
      borderRadius: borderRadius,
      border: Border.all(color: context.sdTheme3.divider),
    ),
    alignment: Alignment.center,
    child: SdIconV3(
      Symbols.image_rounded,
      size: SdIconV3.defaultSize,
      color: context.sdTheme3.textTertiary,
    ),
  );
}
