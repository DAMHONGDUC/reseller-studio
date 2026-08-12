/// Form validation that more than one screen needs.
///
/// **These say whether a value is usable, never what to tell the user** — the
/// message is a localized string the screen picks, and a validator that
/// returned one would put English in `core/`.
final class ValidatorUtils {
  /// The shortest password Firebase Auth will accept.
  ///
  /// Enforced client-side too, so a seller finds out while typing rather than
  /// after a round trip that fails with `weak-password`.
  static const int minPasswordLength = 6;

  /// Deliberately loose: one `@`, something either side, a dot in the domain.
  ///
  /// A stricter pattern rejects addresses that are perfectly valid — the RFC
  /// permits far more than any regex people actually write — and the real
  /// check is that the verification email arrives.
  static bool isEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

  static bool isStrongEnough(String password) =>
      password.length >= minPasswordLength;

  /// True when the string has anything in it at all — the whole of the
  /// validation on a Quick Add title (hard rule 2).
  static bool isNotBlank(String? value) =>
      value != null && value.trim().isNotEmpty;
}
