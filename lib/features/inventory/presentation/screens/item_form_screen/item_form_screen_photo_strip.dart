part of 'item_form_screen.dart';

/// The photos already attached, and the two ways to add one.
///
/// Camera first, library second: a seller filling this in is usually holding
/// the object, and the shot they want does not exist yet.
class _PhotoStrip extends ConsumerWidget {
  const _PhotoStrip();

  static double get tileSize => SdSpacingConstant.r64;

  Future<void> _add(
    BuildContext context,
    WidgetRef ref, {
    required bool fromCamera,
  }) async {
    try {
      await ref
          .read(itemFormControllerProvider.notifier)
          .addPhoto(fromCamera: fromCamera);
    } on PermissionBlocked catch (blocked) {
      // Logged where it was raised; the way out is Settings, not an error.
      if (!context.mounted) return;

      await PermissionSettingsSheet.show(
        context,
        permission: blocked.permission,
      );
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItemFormState state = ref.watch(itemFormControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.itemPhotos,
          style: context.textTheme3.titleSmall!.semiBold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SizedBox(
          height: tileSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.photoUrls.length + 1,
            separatorBuilder: (BuildContext context, int index) =>
                SizedBox(width: SdSpacingConstant.w8),
            itemBuilder: (BuildContext context, int index) {
              if (index == state.photoUrls.length) {
                return _AddPhotoTile(
                  isBusy: state.isUploadingPhoto,
                  onCamera: () => _add(context, ref, fromCamera: true),
                  onLibrary: () => _add(context, ref, fromCamera: false),
                );
              }

              final String url = state.photoUrls[index];

              return _PhotoTile(
                url: url,
                onRemove: () => ref
                    .read(itemFormControllerProvider.notifier)
                    .removePhoto(url),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      AppPhoto(url: url, size: _PhotoStrip.tileSize),
      Positioned(
        top: 0,
        right: 0,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: EdgeInsets.all(SdSpacingConstant.w2),
            decoration: BoxDecoration(
              color: context.sdTheme3.surfaceModal,
              shape: BoxShape.circle,
              border: Border.all(color: context.sdTheme3.border),
            ),
            child: SdIconV3(
              AppIconConstant.close,
              size: SdIconV3.smallSize,
              color: context.sdTheme3.danger,
              semanticLabel: context.l10n.itemRemovePhoto,
            ),
          ),
        ),
      ),
    ],
  );
}

/// The two add affordances, side by side inside one tile-sized slot.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.isBusy,
    required this.onCamera,
    required this.onLibrary,
  });

  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _AddPhotoButton(
        icon: AppIconConstant.photoCamera,
        label: context.l10n.itemTakePhoto,
        isBusy: isBusy,
        onTap: onCamera,
      ),
      SizedBox(width: SdSpacingConstant.w8),
      _AddPhotoButton(
        icon: AppIconConstant.photoLibrary,
        label: context.l10n.itemChoosePhoto,
        isBusy: isBusy,
        onTap: onLibrary,
      ),
    ],
  );
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({
    required this.icon,
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: _PhotoStrip.tileSize,
        height: _PhotoStrip.tileSize,
        decoration: BoxDecoration(
          color: context.sdTheme3.surfaceSunken,
          borderRadius: SdRadiusV3.thumbnailAll,
          border: Border.all(color: context.sdTheme3.border),
        ),
        alignment: Alignment.center,
        child: isBusy
            ? const SdLoadingV3()
            : SdIconV3(icon, color: context.sdTheme3.textSecondary),
      ),
    ),
  );
}
