import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// A declarative route that keeps bottom sheets addressable by GoRouter.
class AppBottomSheetPage<T> extends Page<T> {
  const AppBottomSheetPage({required this.builder, super.key, super.name});

  final WidgetBuilder builder;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    modalBarrierColor: context.sdTheme3.barrier,
  );
}
