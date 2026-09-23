import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../constants/log_tag_constant.dart';
import '../error/failure_mapper.dart';
import 'file_uploader.dart';

/// A guest's photos and receipts, kept on the device
/// (`docs/rules/GUEST_MODE.md`).
///
/// **The copy is the whole job, and it is not optional.** `image_picker`
/// returns a path in the OS cache, which the system is free to delete at any
/// time — a record pointing at one is a photo that vanishes days later with
/// nothing to explain it. The file is copied somewhere app-private and the
/// record points at the copy.
///
/// **Nothing renders differently for it.** `AppPhoto` already takes a local
/// path as readily as an https URL, which is what the test uploader relies
/// on — a guest's photo goes through the same widget as everyone else's.
///
/// The drain uploads these at sign-in and rewrites the record, so a path only
/// lives as long as the account it is waiting for.
class GuestFileUploader implements FileUploader {
  const GuestFileUploader();

  /// The folder every guest file lands under, inside app-private storage.
  static const String rootFolder = 'guest_files';

  static const Uuid _uuid = Uuid();

  @override
  Future<String> upload({
    required FileFolder folder,
    required String recordId,
    required String filePath,
  }) => FailureMapper.guard('store file', () async {
    final Directory root = await getApplicationSupportDirectory();
    final Directory destination = Directory(
      '${root.path}/$rootFolder/${folder.folderName}/$recordId',
    );

    await destination.create(recursive: true);

    // A uuid rather than the original name, for the reason
    // `FirebaseFileUploader` gives: two photos from one phone are both
    // `IMG_0001`, and the second would silently replace the first.
    final String stored =
        '${destination.path}/${_uuid.v4()}${_extensionOf(filePath)}';

    await File(filePath).copy(stored);

    // The record id and the folder, never the file's own name — a filename
    // can carry a customer's name off a scanned receipt (hard rule 9).
    SdLogger.info(
      LogTagConstant.storage,
      'File stored locally',
      <String, Object>{'folder': folder.folderName, 'recordId': recordId},
    );

    return stored;
  });

  @override
  Future<void> delete(String url) =>
      FailureMapper.guard('delete file', () async {
        final File file = File(url);

        // Already gone is what the caller wanted, the same contract the
        // Firebase uploader keeps.
        if (!file.existsSync()) return;

        await file.delete();

        SdLogger.info(LogTagConstant.storage, 'Local file deleted');
      });

  static String _extensionOf(String path) {
    final int dot = path.lastIndexOf('.');
    final int slash = path.lastIndexOf('/');

    if (dot < 0 || dot < slash) return '';

    return path.substring(dot);
  }
}
