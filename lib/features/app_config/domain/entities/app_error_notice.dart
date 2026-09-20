import '../enums/app_notice_type.dart';

/// The owner's remote notice: a screen the app can be told to show instead of
/// itself.
///
/// What it is for is the hour between "the backend is wrong" and "a fix is in
/// the store" — a planned migration, an outage, a marketplace that stopped
/// answering. The seller gets a sentence the owner typed rather than five tabs
/// of numbers that are quietly untrue.
///
/// **It is the most dangerous field in `app_config`, and every default here
/// exists because of that.** A mistake in this block blanks the app for every
/// seller at once, and there is no way to ship them out of it — the same shape
/// as the forced update, and the same conclusion: everything falls back to
/// *not* showing.
class AppErrorNotice {
  const AppErrorNotice({
    this.enabled = false,
    this.title = '',
    this.subtitle1 = '',
    this.subtitle2 = '',
    this.type = AppNoticeType.error,
  });

  /// What a client with no config, a malformed block or a missing one reads.
  static const AppErrorNotice none = AppErrorNotice();

  /// The owner's switch. False until the document says otherwise in so many
  /// words — a missing field, a string where a bool belongs, an unreachable
  /// Firestore all leave the app running.
  final bool enabled;

  /// The line the seller reads first.
  final String title;

  /// What it means for them.
  final String subtitle1;

  /// A second line, quieter — what to do, or when to come back. Empty draws
  /// no row at all rather than a blank one.
  final String subtitle2;

  /// Whether this reads as broken or as something to know.
  final AppNoticeType type;

  /// Whether the app hands the screen over to this notice.
  ///
  /// **A title is required on top of the switch**, and that is not belt and
  /// braces: a notice with no words is a blank screen with no way out, which
  /// is worse than the state it was turned on to explain. The switch alone
  /// cannot produce one.
  bool get shows => enabled && title.isNotEmpty;

  /// **Lengths, never the text.** The words are the owner's and they are
  /// already on every seller's screen; what a reader of the log needs is
  /// whether the block arrived and which way it read.
  Map<String, Object?> toLogData() => <String, Object?>{
    'enabled': enabled,
    'type': type.name,
    'shows': shows,
    'titleLength': title.length,
    'hasSubtitle2': subtitle2.isNotEmpty,
  };
}
