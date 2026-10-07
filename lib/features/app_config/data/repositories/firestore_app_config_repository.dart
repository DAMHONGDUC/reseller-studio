import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/firestore/firestore_maintenance.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/repositories/app_config_repository.dart';
import '../dtos/app_config_dto.dart';

/// The one document at `app_config/current`.
///
/// **Every snapshot is logged with the project it came from and whether it
/// came from the cache.** Those two facts are the whole of "I changed the
/// document and the app did not notice": either the binary is listening to
/// the other flavour's project, or the device is serving what it already had.
/// Both are invisible without saying so.
///
/// **It never lets an error reach the app.** Every other stream in `data/`
/// maps a failure and rethrows it (`FirestoreStream`), because a screen with
/// no data has something to say. This one has no screen: it decides whether
/// the plan system applies, and a seller whose read failed must land on the
/// fallback rather than on an error that would leave every gate undecided.
class FirestoreAppConfigRepository implements AppConfigRepository {
  const FirestoreAppConfigRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, Object?>> get _document =>
      _firestore.collection(AppConfigDto.collection).doc(AppConfigDto.document);

  @override
  Stream<AppConfig> watch() => FirestoreMaintenance.listen(_document.snapshots)
      .map((DocumentSnapshot<Map<String, Object?>> doc) {
        final AppConfig config = doc.exists
            ? AppConfigDto.toEntity(doc)
            : AppConfig.fallback;

        // - the project, because a console edit that "did nothing" is most
        //   often an edit to the other flavour's document
        // - fromCache, because the alternative answer is a device with no
        //   route to the server serving what it already had
        SdLogger.info(
          LogTagConstant.appConfig,
          'App config read',
          <String, Object?>{
            'project': _firestore.app.options.projectId,
            'fromCache': doc.metadata.isFromCache,
            'exists': doc.exists,
            ...config.toLogData(),
          },
        );

        return config;
      })
      // Swallowed rather than rethrown: the stream stops, the provider keeps
      // falling back, and the app carries on with monetisation on.
      .handleError((Object error, StackTrace stackTrace) {
        SdLogger.error(
          LogTagConstant.appConfig,
          'Failed to read app config — falling back',
          error: error,
          stackTrace: stackTrace,
        );
      });
}
