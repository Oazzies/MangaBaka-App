import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

class MBLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const MBLoginButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return MbPrimaryButton(
      label: l10n.translate('login_with'),
      onPressed: onPressed,
      busy: isLoading,
      expand: false,
    );
  }
}
