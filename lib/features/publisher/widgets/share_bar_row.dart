import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A tag's share of the publisher's catalog against its share of the whole
/// site. The bar is the publisher's share; the tick marks the site-wide share.
class ShareBarRow extends StatelessWidget {
  final String label;
  final double share;
  final double catalogShare;
  final int count;
  final VoidCallback? onTap;

  const ShareBarRow({
    super.key,
    required this.label,
    required this.share,
    required this.catalogShare,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  color: onTap == null ? colors.textMuted : colors.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final tick = (catalogShare.clamp(0.0, 1.0) * w);
                  return SizedBox(
                    height: 12,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 8,
                          width: share.clamp(0.0, 1.0) * w,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Positioned(
                          left: tick - 1,
                          child: Container(
                            width: 2,
                            height: 12,
                            color: colors.text.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                '${(share * 100).toStringAsFixed(share < 0.1 ? 1 : 0)}%',
                textAlign: TextAlign.end,
                style: AppTypography.sans(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
