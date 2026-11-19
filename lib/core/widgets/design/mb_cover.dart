import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class MbCover extends StatelessWidget {
  final String url;
  final double width;

  final double? height;
  final double radius;
  final BoxFit fit;
  final int? memCacheWidth;
  final bool blurred;

  final String? heroTag;

  const MbCover({
    super.key,
    required this.url,
    required this.width,
    this.height,
    this.radius = 14,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.blurred = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? width * 1.5;
    final cover = ClipRRect(
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
          blurred: blurred,
        ),
      ),
    );
    final tag = heroTag;
    return tag == null ? cover : Hero(tag: tag, child: cover);
  }
}
