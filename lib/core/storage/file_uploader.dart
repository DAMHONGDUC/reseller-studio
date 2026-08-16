/// What kind of binary is being stored, and therefore where it goes.
///
/// The folder is part of the Storage path, and `storage.rules` reads the
/// workspace id out of that path to decide access — so this enum is a
/// security-relevant value, not a cosmetic one.
enum FileFolder {
  items,
  receipts,
  logo;

  String get folderName => switch (this) {
    FileFolder.items => 'items',
    FileFolder.receipts => 'receipts',
    FileFolder.logo => 'logo',
  };
}

/// Putting a photo or a receipt somewhere it can be read back from.
///
/// **The app never names a bucket or a full path** — it says what kind of
/// file this is and which record it belongs to, and the implementation builds
/// the path that `storage.rules` expects. A path typed at a call site is one
/// typo away from a file nobody can read.
///
/// Returns a URL the app can render. In live mode that is an https download
/// URL; in mock mode it is the local file's own path, which is why every
/// photo in the app renders through `AppPhoto` rather than `Image.network`.
abstract interface class FileUploader {
  Future<String> upload({
    required FileFolder folder,
    required String recordId,
    required String filePath,
  });

  /// Remove a stored file. Silently succeeds when it is already gone — a
  /// delete that fails because the thing is absent has got what it wanted.
  Future<void> delete(String url);
}
