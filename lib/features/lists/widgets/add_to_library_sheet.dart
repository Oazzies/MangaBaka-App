import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/features/lists/widgets/no_tap_flash.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// The status [series] joins the library with, or null when dismissed.
Future<String?> showAddToLibrarySheet(BuildContext context, Series series) =>
    showAdaptiveSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      constraints: const BoxConstraints(maxWidth: 440),
      builder: (_) => SafeArea(child: AddToLibraryChoice(series: series)),
    );

class AddToLibraryChoice extends StatefulWidget {
  static const List<String> states = [
    'plan_to_read',
    'reading',
    'considering',
    'completed',
    'paused',
    'dropped',
  ];

  final Series series;

  const AddToLibraryChoice({super.key, required this.series});

  @override
  State<AddToLibraryChoice> createState() => _AddToLibraryChoiceState();
}

class _AddToLibraryChoiceState extends State<AddToLibraryChoice> {
  final LocalizationService _l10n = LocalizationService();
  late String _state =
      AddToLibraryChoice.states.contains(SettingsManager().addLibraryDefaultTab)
      ? SettingsManager().addLibraryDefaultTab
      : AddToLibraryChoice.states.first;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final series = widget.series;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MbCover(
                url: series.coverUrl,
                width: 44,
                radius: 6,
                memCacheWidth: 120,
                blurred: WidgetUtils.isRatingBlurred(series.contentRating),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.translate('add_to_library').toUpperCase(),
                      style: AppTypography.display(color: c.text, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      series.getDisplayTitle(
                        SettingsManager().defaultTitleLanguage,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: c.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NoTapFlash(
            child: Column(
              children: [
                for (final state in AddToLibraryChoice.states)
                  ListTile(
                    key: ValueKey('library_state_$state'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    onTap: () => setState(() => _state = state),
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.forState(state),
                        shape: BoxShape.circle,
                      ),
                    ),
                    minLeadingWidth: 10,
                    title: Text(
                      _l10n.translate(state),
                      style: AppTypography.sans(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      state == _state
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: state == _state ? c.accent : c.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MbPrimaryButton(
            key: const ValueKey('add_to_library_confirm'),
            label: _l10n.translate('add_to_library'),
            icon: Icons.add_rounded,
            onPressed: () => Navigator.of(context).pop(_state),
          ),
        ],
      ),
    );
  }
}
