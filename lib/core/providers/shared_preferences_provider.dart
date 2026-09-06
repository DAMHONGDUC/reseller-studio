import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device's own key-value store, as an async provider so nothing blocks
/// startup on it.
///
/// Every key it holds is named in `PrefsKeyConstant` — a string typed at a
/// call site is one no rename can follow.
final FutureProvider<SharedPreferences> sharedPreferencesProvider =
    FutureProvider<SharedPreferences>(
      (Ref ref) => SharedPreferences.getInstance(),
    );
