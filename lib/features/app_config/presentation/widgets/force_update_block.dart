import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import 'force_update_sheet.dart';

/// Puts [ForceUpdateSheet] on screen: the dimmed barrier behind it, the
/// bottom alignment, the sheet's ceiling on a wide window, and the one
/// animation it enters on.
///
/// **It is a widget rather than `showSdBottomSheetV3`, and that is the whole
/// bug it exists to fix.** A modal sheet is a pageless route attached to the
/// page route under it, and go_router rebuilds that page list on every
/// redirect — so the sheet raised over the splash was thrown away the moment
/// auth resolved and the app went to Home, and nothing brought it back
/// because the config had not changed. Drawn in the tree instead, the block
/// belongs to the gate that owns it and no navigation can take it away.
///
/// **The barrier is not dismissible and swallows every tap**, which is what
/// `SdBottomSheetExitV3.blocked` bought from the route before.
class ForceUpdateBlock extends StatefulWidget {
  const ForceUpdateBlock({super.key});

  @override
  State<ForceUpdateBlock> createState() => _ForceUpdateBlockState();
}

class _ForceUpdateBlockState extends State<ForceUpdateBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SdMotionV3.slow,
  );

  late final Animation<double> _entry = CurvedAnimation(
    parent: _controller,
    curve: SdMotionV3.standard,
  );

  @override
  void initState() {
    super.initState();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// [Material] because this sits above the router's navigator, where there is
  /// no scaffold — the route normally carries one and the ink, the text
  /// baseline and the button's splash all want it.
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        FadeTransition(
          opacity: _entry,
          child: ModalBarrier(
            color: context.sdTheme3.barrier,
            dismissible: false,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_entry),
            child: ConstrainedBox(
              // A panel keeps a ceiling, the same one the presenter applies.
              constraints: BoxConstraints(
                maxWidth: SdContentPaddingV3.maxSheetWidth,
              ),
              child: const SdBottomSheetExitScopeV3(
                exit: SdBottomSheetExitV3.blocked,
                child: ForceUpdateSheet(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
