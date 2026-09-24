import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/carrier.dart';

class CarrierFormController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String?> submit({required String name, String? carrierId}) async {
    final String trimmed = name.trim();
    final String id = carrierId ?? SdId.unique();

    if (trimmed.isEmpty || state) return null;

    state = true;
    SdLogger.action(
      LogTagConstant.order,
      'Carrier form submitted',
      <String, Object>{'carrierId': id, 'isEditing': carrierId != null},
    );

    try {
      final List<Carrier> existing = await ref
          .read(carrierRepositoryProvider)
          .watchCarriers()
          .first;
      final Carrier? current = existing
          .where((Carrier carrier) => carrier.id == id)
          .firstOrNull;

      await ref
          .read(carrierRepositoryProvider)
          .save(
            current == null
                ? Carrier(id: id, name: trimmed, createdAt: DateTime.now())
                : current.copyWith(name: trimmed),
          );

      return id;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.order,
        'Carrier form failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'carrierId': id},
      );
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> delete(String carrierId) async {
    try {
      await ref.read(carrierRepositoryProvider).delete(carrierId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.order,
        'Failed to delete carrier',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'carrierId': carrierId},
      );
      rethrow;
    }
  }
}

final NotifierProvider<CarrierFormController, bool>
carrierFormControllerProvider = NotifierProvider<CarrierFormController, bool>(
  CarrierFormController.new,
);
