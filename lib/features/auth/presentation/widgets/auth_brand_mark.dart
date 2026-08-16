import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A vendor sign-in logo, drawn to fill the slot [SdButtonV3.leading] gives it.
///
/// The artwork is the vendor's own file (`BrandAssetConstant`) — this widget
/// only decides how it is painted, and the two vendors want opposite things:
///
/// - **Apple's mark is monochrome** and its guidelines require it to take the
///   button's label colour, so it passes a [tint].
/// - **Google's "G" is four colours** and recolouring it breaches their
///   branding guidelines, so it passes none.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({required this.asset, this.tint, super.key});

  final String asset;

  /// Null leaves the artwork's own colours alone. See the class doc.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      fit: BoxFit.contain,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}
