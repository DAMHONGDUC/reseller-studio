import 'package:flutter/widgets.dart';

/// The navigators the router owns.
///
/// **[root] is what makes a detail screen full-screen.** Owner's rule: the
/// glass nav bar belongs to the five tab screens and to nothing else. A route
/// nested inside a `StatefulShellBranch` is pushed onto that *branch's*
/// navigator by default, which leaves the shell — and its bar — drawn over
/// the top of it; naming this key as a route's `parentNavigatorKey` pushes it
/// above the shell instead, so the detail owns the whole window.
///
/// A holder rather than a bare top-level variable, for the same reason
/// `AppRoutes` is one: there is exactly one of these in the app and it is
/// findable by name.
final class AppNavigatorKey {
  static final GlobalKey<NavigatorState> root = GlobalKey<NavigatorState>();
}
