import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';

/// A publisher's logo in a rounded square, or its initial when it has none or
/// it fails to load.
///
/// Logos come in arbitrary aspect ratios, often with transparent backgrounds, so they are contained (never cropped) on a
/// raised surface.
class PublisherLogoView extends StatelessWidget {
  final Publisher publisher;
  final double size;

  const PublisherLogoView({super.key, required this.publisher, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final url = publisher.logo?.forSize(size);
    final radius = BorderRadius.circular(size <= 40 ? 8 : 12);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url == null ? _initial(context) : _image(context, url),
    );
  }

  Widget _image(BuildContext context, String url) {
    final inner = size - 8;
    // Centred at the box's own size: an error or placeholder widget is laid
    // out at the top-left of whatever it is given otherwise.
    Widget fill(Widget child) => SizedBox(
          width: inner,
          height: inner,
          child: Center(child: child),
        );

    return Padding(
      padding: const EdgeInsets.all(4),
      child: WidgetUtils.networkImage(
        url: url,
        width: inner,
        height: inner,
        fit: BoxFit.contain,
        memCacheWidth: WidgetUtils.decodeWidth(context, inner),
        placeholder: const SizedBox.shrink(),
        errorWidget: fill(_initial(context)),
      ),
    );
  }

  Widget _initial(BuildContext context) {
    final name = publisher.name.trim();
    return Center(
      child: Text(
        name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase(),
        textAlign: TextAlign.center,
        style: AppTypography.display(
          color: context.colors.textMuted,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
