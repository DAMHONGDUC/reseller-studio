import 'package:image_picker/image_picker.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import '../permissions/system_permissions.dart';
import 'file_uploader.dart';
import 'photo_picker.dart';

/// Picking a receipt or a photo and putting it in storage, in one call.
///
/// Extracted because three controllers do exactly this — the item form, the
/// expense form and the purchase form — and the sequence is easy to get
/// subtly wrong: a cancelled picker is **not** a failure, and treating it as
/// one shows a seller an error for changing their mind.
///
/// **Images only, for now.** `storage.rules` also accepts a PDF, because a
/// receipt is often a PDF from an email, but `image_picker` cannot return
/// one — a file picker is a separate dependency and a separate decision.
/// Photographing the paper receipt is what sellers do anyway.
final class DocumentPicker {
  /// What a receipt is stored at.
  ///
  /// Higher than an item photo: a receipt has small print, and the whole point
  /// is being able to read it a year later in front of an accountant.
  static const double maxWidth = 2000;
  static const int quality = 90;

  /// Returns the stored URL, or **null when the seller cancelled** — which is
  /// not an error and is not logged as one. A permission refused for good
  /// throws `PermissionBlocked` (see [PhotoPicker]).
  static Future<String?> pickAndUpload({
    required FileUploader uploader,
    required SystemPermissions permissions,
    required FileFolder folder,
    required String recordId,
    required bool fromCamera,
  }) async {
    final XFile? picked = await PhotoPicker.pick(
      permissions: permissions,
      fromCamera: fromCamera,
      maxWidth: maxWidth,
      quality: quality,
    );

    if (picked == null) return null;

    final String url = await uploader.upload(
      folder: folder,
      recordId: recordId,
      filePath: picked.path,
    );

    // The folder and the record, never the file's own name — a scanned
    // receipt's filename can carry a customer's name (hard rule 9).
    SdLogger.info(LogTagConstant.storage, 'Document attached', <String, Object>{
      'folder': folder.folderName,
      'recordId': recordId,
    });

    return url;
  }
}
