import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import 'file_uploader.dart';

/// The test uploader: it stores nothing and hands back the file's own
/// path.
///
/// A widget test has no Firebase project, so a real upload would fail with
/// `[core/no-app]`. Returning the local path means the photo a seller just
/// took still renders on the item they attached it to — which is the whole
/// point of being able to look at the app before the backend exists.
///
/// **The path does not survive a reinstall and is not shared with anyone.**
/// That is fine in a test and is why nothing in the app reaches for it: the
/// only thing that hands it out is `FakeOverrides` in `test/support/`.
class LocalFileUploader implements FileUploader {
  const LocalFileUploader();

  @override
  Future<String> upload({
    required FileFolder folder,
    required String recordId,
    required String filePath,
  }) async {
    SdLogger.info(
      LogTagConstant.storage,
      'File kept locally, not uploaded',
      <String, Object>{'folder': folder.folderName, 'recordId': recordId},
    );

    return filePath;
  }

  @override
  Future<void> delete(String url) async {
    // Nothing was uploaded, so there is nothing to remove. The file itself
    // belongs to the photo library and is not this app's to delete.
    SdLogger.info(
      LogTagConstant.storage,
      'File delete skipped, nothing was uploaded',
    );
  }
}
