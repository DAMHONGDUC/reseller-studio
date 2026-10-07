import 'dart:io';

/// Reads the bars of a sample label back into digits — EAN-13 (and UPC-A,
/// which is EAN-13 with a leading zero) or EAN-8.
///
/// Decodes the drawing, not the printed digits, so a label whose bars drift
/// from its caption fails here instead of at the shop counter.
final class BarcodeLabelDecoder {
  static const List<String> _l = <String>[
    '0001101', '0011001', '0010011', '0111101', '0100011', //
    '0110001', '0101111', '0111011', '0110111', '0001011',
  ];
  static const List<String> _parity = <String>[
    'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG', //
    'LGGLLG', 'LGGGLL', 'GLLLGG', 'GLGLLG', 'GGLLLG',
  ];

  static final RegExp _group = RegExp(
    r'<g id="barcode"[^>]*data-origin="([\d.]+)" data-module="(\d+)" '
    r'data-modules="(\d+)">([\s\S]*?)</g>',
  );
  static final RegExp _rect = RegExp(r'<rect x="([\d.]+)"[^>]*width="(\d+)"');

  /// The digits the bars in the SVG at [path] encode.
  static String decodeSvg(String path) {
    final RegExpMatch group = _group.firstMatch(File(path).readAsStringSync())!;
    final double origin = double.parse(group[1]!);
    final int module = int.parse(group[2]!);
    final List<String> bits = List<String>.filled(int.parse(group[3]!), '0');

    for (final RegExpMatch rect in _rect.allMatches(group[4]!)) {
      final int start = ((double.parse(rect[1]!) - origin) / module).round();
      final int width = int.parse(rect[2]!) ~/ module;

      for (int i = start; i < start + width; i++) {
        bits[i] = '1';
      }
    }

    return decode(bits.join());
  }

  /// [bits] is one character per module, `1` for a bar.
  static String decode(String bits) {
    final int perSide = bits.length == 95 ? 6 : 4;
    final int rightStart = 3 + perSide * 7 + 5;
    final StringBuffer parity = StringBuffer();
    final StringBuffer digits = StringBuffer();

    _expect(bits.length == 95 || bits.length == 67, 'length ${bits.length}');
    _expect(bits.startsWith('101') && bits.endsWith('101'), 'end guards');
    _expect(bits.substring(rightStart - 5, rightStart) == '01010', 'centre');

    for (int i = 0; i < perSide; i++) {
      final String chunk = bits.substring(3 + i * 7, 10 + i * 7);
      final int asL = _l.indexOf(chunk);
      final int asG = _l.indexOf(_invert(chunk).split('').reversed.join());

      _expect(asL >= 0 || asG >= 0, 'left digit $i');
      parity.write(asL >= 0 ? 'L' : 'G');
      digits.write(asL >= 0 ? asL : asG);
    }

    for (int i = 0; i < perSide; i++) {
      final String chunk = bits.substring(
        rightStart + i * 7,
        rightStart + 7 + i * 7,
      );
      final int digit = _l.indexOf(_invert(chunk));

      _expect(digit >= 0, 'right digit $i');
      digits.write(digit);
    }

    final String code = perSide == 6
        ? '${_parity.indexOf(parity.toString())}$digits'
        : digits.toString();

    _expect(!code.startsWith('-1'), 'first-digit parity');
    _expect(_checksumHolds(code), 'check digit');

    return code;
  }

  static bool _checksumHolds(String code) {
    final List<int> body = code
        .substring(0, code.length - 1)
        .split('')
        .map(int.parse)
        .toList()
        .reversed
        .toList();
    int total = 0;

    for (int i = 0; i < body.length; i++) {
      total += body[i] * (i.isEven ? 3 : 1);
    }

    return (10 - total % 10) % 10 == int.parse(code[code.length - 1]);
  }

  static String _invert(String chunk) =>
      chunk.split('').map((String bit) => bit == '1' ? '0' : '1').join();

  static void _expect(bool holds, String what) {
    if (!holds) throw FormatException('Unreadable label: $what');
  }
}
