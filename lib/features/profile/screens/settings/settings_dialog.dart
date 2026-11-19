import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_root_groups.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SettingsDialogPage {
  final String title;
  final Widget content;

  const SettingsDialogPage({required this.title, required this.content});
}

/// Own page stack: a pushed [Navigator] route would cover the dialog with a full-screen page.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static SettingsDialogState? of(BuildContext context) =>
      context.findAncestorStateOfType<SettingsDialogState>();

  @override
  State<SettingsDialog> createState() => SettingsDialogState();
}

class SettingsDialogState extends State<SettingsDialog> {
  static const Duration _pageTransition = Duration(milliseconds: 300);

  static const double _verticalInset = 64;

  final List<SettingsDialogPage> _stack = [];

  bool _isPushing = true;

  void pushCategory(String title, Widget content) {
    setState(() {
      _isPushing = true;
      _stack.add(SettingsDialogPage(title: title, content: content));
    });
  }

  void popCategory() {
    if (_stack.isEmpty) return;
    setState(() {
      _isPushing = false;
      _stack.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SettingsManager(),
        LocalizationService(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final page = _stack.isEmpty ? null : _stack.last;
        final currentKey = page == null
            ? const ValueKey('main_settings')
            : ValueKey(page.title);

        return PopScope(
          canPop: _stack.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            popCategory();
          },
          child: Dialog(
            backgroundColor: context.colors.background,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 48,
              vertical: 32,
            ),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.largeRadius),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.sizeOf(context).height - _verticalInset,
              ),
              child: AnimatedSwitcher(
                duration: _pageTransition,
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) => _slide(
                  child: child,
                  animation: animation,
                  isEntering: child.key == currentKey,
                ),
                child: KeyedSubtree(
                  key: currentKey,
                  child: page == null
                      ? _buildRoot(context, l10n)
                      : _buildCategory(context, page),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _slide({
    required Widget child,
    required Animation<double> animation,
    required bool isEntering,
  }) {
    final fromBelow = _isPushing == isEntering;
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0.0, fromBelow ? 1.0 : -1.0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _buildRoot(BuildContext context, LocalizationService l10n) {
    return _Shell(
      key: const ValueKey('main_settings_column'),
      title: l10n.translate('settings'),
      titleFontSize: 18,
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: buildSettingsGroups(
          context,
          l10n,
          getIt<ProfileAuthService>(),
        ),
      ),
    );
  }

  Widget _buildCategory(BuildContext context, SettingsDialogPage page) {
    return _Shell(
      key: ValueKey('category_column_${page.title}'),
      title: page.title,
      titleFontSize: 19,
      onBack: popCategory,
      onClose: () => Navigator.pop(context),
      child: page.content,
    );
  }
}

class _Shell extends StatelessWidget {
  final String title;
  final double titleFontSize;
  final VoidCallback? onBack;
  final VoidCallback onClose;
  final Widget child;

  const _Shell({
    super.key,
    required this.title,
    required this.titleFontSize,
    this.onBack,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                  color: context.colors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: titleFontSize,
                    letterSpacing: onBack == null ? -0.5 : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
                color: context.colors.textMuted,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.colors.border),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppConstants.horizontalPadding,
              right: AppConstants.horizontalPadding,
              top: 16,
              bottom: 24,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
