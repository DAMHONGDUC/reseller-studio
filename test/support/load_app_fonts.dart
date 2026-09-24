import 'package:flutter/services.dart';

/// Loads the app's real fonts into the test binding.
///
/// **Without this, a widget test measures text against Flutter's built-in
/// test font, not Inter.** That font is wider than Inter at nearly every
/// weight, so `RenderParagraph.didExceedMaxLines` reports false overflow —
/// and, worse, could report false *fit* for other cases, both readings
/// useless once real copy is checked against a maxLines budget. A test that
/// asserts what a phone actually renders loads the phone's font first.
///
/// Mirrors `pubspec.yaml`'s `fonts:` block exactly — a weight added there and
/// not here is a test that keeps measuring the old typeface.
Future<void> loadAppFonts() async {
  await _load('Inter', <int, String>{
    400: 'assets/fonts/Inter-Regular.ttf',
    500: 'assets/fonts/Inter-Medium.ttf',
    600: 'assets/fonts/Inter-SemiBold.ttf',
    700: 'assets/fonts/Inter-Bold.ttf',
  });

  await _load('Inter Display', <int, String>{
    600: 'assets/fonts/InterDisplay-SemiBold.ttf',
    700: 'assets/fonts/InterDisplay-Bold.ttf',
  });
}

Future<void> _load(String family, Map<int, String> weights) async {
  final FontLoader loader = FontLoader(family);

  for (final String path in weights.values) {
    loader.addFont(rootBundle.load(path));
  }

  await loader.load();
}
