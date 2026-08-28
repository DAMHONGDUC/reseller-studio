import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The app's semantic glyph registry.
///
/// Call sites ask for what an icon means. This file alone decides whether the
/// glyph comes from Flutter's Material Icons or the Material Symbols font.
final class AppIconConstant {
  static const IconData add = Symbols.add_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
}
