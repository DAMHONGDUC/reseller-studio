import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import 'file_uploader.dart';

/// The mock-mode uploader: it stores nothing and hands back the file's own
/// path.
///
/// Mock mode has no Firebase project, so a real upload would fail with
/// `[core/no-app]`. Returning the local path means the photo a seller just
/// took still renders on the item they attached it to — which is the whole
/// point of being able to look at the app before the backend exists.
///
/// **The path does not survive a reinstall and is not shared with anyone.**
/// That is fine here and is exactly why mock mode cannot ship: the guard on
/// `DataModeController` is what keeps it out of a release build.
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
      'File kept locally (mock mode)',
      <String, Object>{'folder': folder.folderName, 'recordId': recordId},
    );

    return filePath;
  }

  @override
  Future<void> delete(String url) async {
    // Nothing was uploaded, so there is nothing to remove. The file itself
    // belongs to the photo library and is not this app's to delete.
    SdLogger.info(LogTagConstant.storage, 'File delete skipped (mock mode)');
  }
}
