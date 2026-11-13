import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/link_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';

class WidgetUtils {
  static Widget responsiveConstraint(Widget child, {double maxWidth = 800}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static Widget tooltip({required String message, required Widget child}) {
    return AppTooltip(message: message, child: child);
  }

  static bool isRatingBlurred(String contentRating) => SettingsManager()
      .blurredContentRatings
      .contains(contentRating.toLowerCase());

  /// Rounds up to a 64px step at display density so window resizes do not
  /// re-decode every cover on every frame.
  static int decodeWidth(BuildContext context, double logicalWidth) {
    const step = 64;
    final px = (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ((px + step - 1) ~/ step) * step;
  }

  static final Map<String, int> _decodeWidths = {};

  static int? shownDecodeWidth(String url, {int atLeast = 256}) {
    final w = _decodeWidths[url];
    return w != null && w >= atLeast ? w : null;
  }

  static Widget networkImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    int? memCacheWidth,
    int? memCacheHeight,
    bool blurred = false,
    Duration fadeIn = const Duration(milliseconds: 140),
  }) {
    if (memCacheWidth != null && url.isNotEmpty) {
      if (_decodeWidths.length > 600) _decodeWidths.clear();
      _decodeWidths[url] = memCacheWidth;
    }
    if (url.isEmpty) {
      final iconSize = (width != null && width.isFinite) ? width : 24.0;
      return errorWidget ?? _BrokenImageIcon(size: iconSize);
    }

    final Widget image = url.startsWith('assets/')
        ? Image.asset(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              final iconSize = (width != null && width.isFinite) ? width : 24.0;
              return errorWidget ?? _BrokenImageIcon(size: iconSize);
            },
          )
        : CachedNetworkImage(
            imageUrl: url,
            httpHeaders: const {'User-Agent': AppConstants.userAgent},
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (context, url) =>
                placeholder ?? const _ImagePlaceholder(),
            errorWidget: (context, url, error) {
              LoggingService.logger.warning('Image load failed: $url — $error');
              final iconSize = (width != null && width.isFinite) ? width : 24.0;
              return errorWidget ?? _BrokenImageIcon(size: iconSize);
            },
            fadeOutDuration: Duration.zero,
            filterQuality: FilterQuality.medium,
            fadeInDuration: fadeIn,
          );

    if (!blurred) return image;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: image,
    );
  }

  static Widget chipWrap(
    String label,
    List<String> items, {
    Color? color,
    Function(String)? onChipTap,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SectionLabel(label),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (e) => ChipBase(
                  backgroundColor: color,
                  label: SelectableText(e),
                  onTap: onChipTap != null ? () => onChipTap(e) : null,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static Widget linkList(List<dynamic> links) {
    if (links.isEmpty) return const SizedBox.shrink();
    final chips = links
        .map(HoverableLinkChip.fromDynamic)
        .whereType<Widget>()
        .toList();
    if (chips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: _SectionLabel('Links'),
        ),
        Wrap(spacing: 12, runSpacing: 12, children: chips),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// A reactive tooltip that listens to [SettingsManager] to show or hide itself.
class AppTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const AppTooltip({super.key, required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        if (!SettingsManager().showTooltips) return child;
        return Tooltip(message: message, child: child);
      },
    );
  }
}

class _BrokenImageIcon extends StatelessWidget {
  final double size;
  const _BrokenImageIcon({required this.size});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.broken_image, size: size, color: context.colors.textMuted);
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.colors.surface);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTypography.monoLabel(
      color: context.colors.textMuted,
      fontSize: 11.5,
    ),
  );
}
