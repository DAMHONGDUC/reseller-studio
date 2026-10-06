/// The frame the scanner reads inside.
///
/// Wider than tall because most of what a seller scans is a 1D barcode; a QR
/// code still reads, since a code only has to cross the frame to count.
final class ScannerConstant {
  /// The frame's width, as a share of the camera view's shorter side.
  static const double windowWidthFactor = 0.8;

  /// Width over height.
  static const double windowAspectRatio = 1.6;
}
