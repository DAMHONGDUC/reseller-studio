import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';

void main() {
  test('semantic icons resolve through the app registry', () {
    expect(AppIconConstant.add, Symbols.add_rounded);
    expect(AppIconConstant.delete, Icons.delete_outline_rounded);
  });
}
