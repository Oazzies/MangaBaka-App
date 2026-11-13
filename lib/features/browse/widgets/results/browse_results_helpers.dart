import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_list_controls.dart';

class BrowseResultsHelpers {
  BrowseResultsHelpers._();

  static Map<String, dynamic> buildRequestParams({
    required int page,
    required String sortBy,
    String? staff,
    String? publisherId,
    String? publisher,
    String? genre,
    String? tag,
    String? excludeUserId,
    double? randomSeed,
  }) {
    final params = <String, dynamic>{
      'limit': AppConstants.defaultPageLimit,
      'page': page,
    };

    if (staff != null) params['staff'] = staff;
    if (publisherId != null) {
      params['publisher_id'] = publisherId;
    } else if (publisher != null) {
      params['publisher'] = publisher;
    }
    if (genre != null) params['genre'] = genre;
    if (tag != null) params['tag'] = tag;
    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      params['exclude_user_library'] = excludeUserId;
    }
    if (sortBy == 'random' && randomSeed != null) {
      params['random_seed'] = randomSeed;
    }

    return params;
  }

  static String buildTitleText({
    required LocalizationService l10n,
    required String sortType,
    String? staff,
    String? publisher,
    String? refineLabel,
  }) {
    if (staff != null) {
      return l10n
          .translate('staff_works_title')
          .replaceAll('{name}', l10n.formatPossessive(staff));
    }
    if (publisher != null) {
      final name = l10n.formatPossessive(publisher);
      final refine = refineLabel;
      if (refine != null && refine.isNotEmpty) {
        return l10n
            .translate('publisher_works_of')
            .replaceAll('{name}', name)
            .replaceAll('{subject}', refine);
      }
      return l10n.translate('staff_works_title').replaceAll('{name}', name);
    }
    return sortType;
  }
}

class BrowseResultsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const BrowseResultsAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: context.colors.text),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: AppTypography.display(color: context.colors.text, fontSize: 17),
      ),
      actions: [
        if (DesktopLayout.isActive(context))
          Padding(
            padding: const EdgeInsets.only(
              right: DesktopTokens.windowControlsClearance,
            ),
            child: DesktopListStyleToggle(scope: DesktopListScope.browse),
          ),
      ],
    );
  }
}
