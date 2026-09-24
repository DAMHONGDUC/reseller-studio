import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import '../error/failure_mapper.dart';
import 'file_uploader.dart';

/// Firebase Storage, behind the [FileUploader] interface.
///
/// The path is always
/// `workspaces/{workspaceId}/{folder}/{recordId}/{uuid}{extension}`, which is
/// exactly the shape `storage.rules` matches on. The uuid rather than the
/// original filename: two photos taken on the same phone are both `IMG_0001`,
/// and the second would silently replace the first.
class FirebaseFileUploader implements FileUploader {
  /// Positional because Dart cannot name a private field as a named
  /// parameter, and both arguments are different enough that a swap would not
  /// compile.
  const FirebaseFileUploader(this._storage, this._workspaceId);

  final FirebaseStorage _storage;
  final String _workspaceId;

  @override
  Future<String> upload({
    required FileFolder folder,
    required String recordId,
    required String filePath,
  }) => FailureMapper.guard('upload file', () async {
    final String extension = _extensionOf(filePath);
    final Reference reference = _storage.ref(
      'workspaces/$_workspaceId/${folder.folderName}/$recordId/'
      '${SdId.unique()}$extension',
    );

    await reference.putFile(File(filePath));

    final String url = await reference.getDownloadURL();

    // The record id and the folder, never the file's own name — a photo
    // filename can carry a customer's name off a scanned receipt.
    SdLogger.info(LogTagConstant.storage, 'File uploaded', <String, Object>{
      'folder': folder.folderName,
      'recordId': recordId,
    });

    return url;
  });

  @override
  Future<void> delete(String url) =>
      FailureMapper.guard('delete file', () async {
        try {
          await _storage.refFromURL(url).delete();
        } catch (error, stackTrace) {
          // A file that is already gone has given the caller what it wanted,
          // so this does not propagate — but it is still logged, because a
          // delete failing for any *other* reason is how orphaned files
          // accumulate unnoticed (hard rule 8).
          SdLogger.error(
            LogTagConstant.storage,
            'Could not delete stored file',
            error: error,
            stackTrace: stackTrace,
          );
        }
      });

  /// `.jpg` from a path, or empty when there is none. Lower-cased, because
  /// Storage content-type sniffing is case sensitive and `IMG.JPG` would come
  /// back as an octet stream the rules reject.
  static String _extensionOf(String path) {
    final int dot = path.lastIndexOf('.');

    if (dot == -1 || dot == path.length - 1) return '';

    return path.substring(dot).toLowerCase();
  }
}
