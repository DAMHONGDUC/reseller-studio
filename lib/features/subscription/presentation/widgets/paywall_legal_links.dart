import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/link_utils.dart';

/// The two compact legal links at the bottom of the purchase sheet.
class PaywallLegalLinks extends StatelessWidget {
  const PaywallLegalLinks({
    required this.termsUrl,
    required this.privacyUrl,
    super.key,
  });

  final String termsUrl;
  final String privacyUrl;

  Future<void> _open(BuildContext context, String url) async {
    final bool opened = await LinkUtils.open(url);

    if (context.mounted && !opened) {
      SdSnackBarUtilsV3.error(context, context.l10n.legalCouldNotOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (termsUrl.isEmpty && privacyUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (termsUrl.isNotEmpty)
          Flexible(
            child: TextButton(
              onPressed: () => _open(context, termsUrl),
              child: Text(
                context.l10n.legalTermsOfUse,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (termsUrl.isNotEmpty && privacyUrl.isNotEmpty)
          Text(
            '•',
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
        if (privacyUrl.isNotEmpty)
          Flexible(
            child: TextButton(
              onPressed: () => _open(context, privacyUrl),
              child: Text(
                context.l10n.legalPrivacyPolicy,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}
