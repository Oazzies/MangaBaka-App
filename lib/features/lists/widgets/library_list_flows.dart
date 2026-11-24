import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/widgets/add_series_to_list_form.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_dialogs.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_form.dart';
import 'package:mangabaka_app/features/lists/widgets/list_action_menu.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';

enum ListMenuAction { edit, privacy, delete }

/// The dialogs, confirmations and toasts around [LibraryListsController], shared by every layout.
class LibraryListFlows {
  final LibraryListsController lists;
  final SeriesSearchService? search;
  final LocalizationService l10n;

  LibraryListFlows(this.lists, {this.search, LocalizationService? l10n})
    : l10n = l10n ?? LocalizationService();

  /// A `_one` variant of [key] for a count of one, as the stacks strings do.
  String _t(String key, [Map<String, String> args = const {}]) {
    if (args['count'] == '1') key = '${key}_one';
    var out = l10n.translate(key);
    args.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  void _toast(BuildContext context, String? errorKey, String success) {
    if (!context.mounted) return;
    if (errorKey != null) {
      AppSnackBar.show(context, l10n.translate(errorKey), isError: true);
    } else {
      AppSnackBar.show(context, success);
    }
  }

  /// With [addSeriesId], the new list also gets that series.
  Future<LibraryList?> create(
    BuildContext context, {
    String? addSeriesId,
  }) async {
    LibraryList? created;
    String? addError;
    await showLibraryListForm(
      context,
      onSubmit: (name, isPrivate) async {
        final (list, error) = await lists.create(name, isPrivate: isPrivate);
        if (list == null) return error;
        created = list;
        if (addSeriesId != null) {
          addError = await lists.setMembership(
            addSeriesId,
            list.id,
            member: true,
          );
        }
        return null;
      },
    );
    final list = created;
    if (list != null && context.mounted) {
      _toast(context, addError, _t('lists_created', {'name': list.name}));
    }
    return list;
  }

  Future<void> edit(BuildContext context, LibraryList list) =>
      showLibraryListForm(
        context,
        editing: list,
        onSubmit: (name, isPrivate) =>
            lists.edit(list.id, name, isPrivate: isPrivate),
      );

  Future<void> addSeries(BuildContext context, LibraryList list) =>
      showAddSeriesToList(context, lists, list, search: search);

  Future<void> togglePrivate(BuildContext context, LibraryList list) async {
    final makePrivate = !list.isPrivate;
    final error = await lists.setPrivate(list.id, isPrivate: makePrivate);
    if (!context.mounted) return;
    _toast(
      context,
      error,
      _t(makePrivate ? 'lists_now_private' : 'lists_now_public', {
        'name': list.name,
      }),
    );
  }

  Future<bool> delete(BuildContext context, LibraryList list) async {
    final ok = await confirmListAction(
      context,
      title: _t('lists_delete_title', {'name': list.name}),
      body: l10n.translate('lists_delete_body'),
      confirmLabel: l10n.translate('lists_delete'),
    );
    if (!ok || !context.mounted) return false;
    final error = await lists.delete(list.id);
    if (!context.mounted) return error == null;
    _toast(context, error, _t('lists_deleted', {'name': list.name}));
    return error == null;
  }

  Future<void> deleteSelected(BuildContext context) async {
    final count = lists.selected.length;
    final ok = await confirmListAction(
      context,
      title: _t('lists_delete_many_title', {'count': '$count'}),
      body: l10n.translate('lists_delete_body'),
      confirmLabel: l10n.translate('lists_delete'),
    );
    if (!ok || !context.mounted) return;
    final error = await lists.deleteSelected();
    if (!context.mounted) return;
    _toast(context, error, _t('lists_deleted_many', {'count': '$count'}));
  }

  Future<void> setSelectedPrivate(
    BuildContext context, {
    required bool isPrivate,
  }) async {
    final count = lists.selected.length;
    final error = await lists.setSelectedPrivate(isPrivate: isPrivate);
    if (!context.mounted) return;
    _toast(
      context,
      error,
      _t(isPrivate ? 'lists_many_private' : 'lists_many_public', {
        'count': '$count',
      }),
    );
  }

  /// [onDeleted] runs after a confirmed, successful delete.
  Future<void> showMenu(
    BuildContext context,
    LibraryList list, {
    Rect? anchor,
    VoidCallback? onDeleted,
  }) => showListActionMenu<ListMenuAction>(
    context,
    anchor: anchor,
    title: list.name,
    items: [
      ListMenuItem(
        value: ListMenuAction.edit,
        label: l10n.translate('lists_edit'),
        icon: Icons.edit_rounded,
      ),
      ListMenuItem(
        value: ListMenuAction.privacy,
        label: l10n.translate(
          list.isPrivate ? 'lists_make_public' : 'lists_make_private',
        ),
        icon: list.isPrivate ? Icons.public_rounded : Icons.lock_rounded,
      ),
      ListMenuItem(
        value: ListMenuAction.delete,
        label: l10n.translate('lists_delete'),
        icon: Icons.delete_outline_rounded,
        destructive: true,
      ),
    ],
    onSelected: (action) async {
      switch (action) {
        case ListMenuAction.edit:
          await edit(context, list);
        case ListMenuAction.privacy:
          await togglePrivate(context, list);
        case ListMenuAction.delete:
          if (await delete(context, list)) onDeleted?.call();
      }
    },
  );
}
