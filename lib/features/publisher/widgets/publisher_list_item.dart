import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class PublisherListItem extends StatelessWidget {
  final Publisher publisher;
  final VoidCallback onTap;

  const PublisherListItem({
    super.key,
    required this.publisher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppConstants.tertiaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: AppConstants.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      publisher.name,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge(publisher.subType.toUpperCase()),
                        if (publisher.founded != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoText('Est. ${publisher.founded}'),
                        ],
                        if (publisher.closed != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoText('Closed ${publisher.closed}', isError: true),
                        ],
                        if (publisher.imprints.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildInfoText('${publisher.imprints.length} Imprints'),
                        ],
                        if (publisher.links.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: AppConstants.accentColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                    if (publisher.description != null && publisher.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        publisher.description!,
                        style: TextStyle(
                          color: AppConstants.textMutedColor,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppConstants.textMutedColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppConstants.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppConstants.accentColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text, {bool isError = false}) {
    return Text(
      text,
      style: TextStyle(
        color: isError ? AppConstants.errorColor.withValues(alpha: 0.8) : AppConstants.textMutedColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
