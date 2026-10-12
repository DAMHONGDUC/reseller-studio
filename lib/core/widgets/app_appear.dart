import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// A row that fades and grows in the first time it is drawn, when [animate]
/// says it is new (`docs/UI_POLISH_PLAN.md`) — a Quick Add landing in the
/// list is seen arriving rather than found later.
///
/// Only new rows animate: a row rebuilt by scrolling must not fade in again,
/// so the caller decides what "new" is from the record, not from the widget.
class AppAppear extends StatefulWidget {
  const AppAppear({required this.animate, required this.child, super.key});

  final bool animate;
  final Widget child;

  @override
  State<AppAppear> createState() => _AppAppearState();
}

class _AppAppearState extends State<AppAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.animate ? 0 : 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: SdMotionV3.standard,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.duration = SdMotionV3.of(context, SdMotionV3.normal);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _curve,
    alignment: Alignment.topCenter,
    child: FadeTransition(opacity: _curve, child: widget.child),
  );
}
