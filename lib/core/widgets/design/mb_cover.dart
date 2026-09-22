import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A series cover at the design system's corner radius, with a consistent
/// placeholder well behind it.
///
/// Wraps [WidgetUtils.networkImage] rather than re-implementing caching, so
/// asset URLs, blur and memory-cache sizing keep working unchanged.
class MbCover extends StatelessWidget {
  final String url;
  final double width;

  /// Defaults to the 2:3 cover ratio the API's images use.
  final double? height;
  final double radius;
  final BoxFit fit;
  final int? memCacheWidth;

  const MbCover({
    super.key,
    required this.url,
    required this.width,
    this.height,
    this.radius = 14,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? width * 1.5;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: h,
        color: context.colors.surfaceRaised,
        child: WidgetUtils.networkImage(
          url: url,
          width: width,
          height: h,
          fit: fit,
          memCacheWidth: memCacheWidth,
        ),
      ),
    );
  }
}
