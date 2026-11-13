import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';

/// Which stacks a [StacksListScreen] pages through.
sealed class StacksListSource {
  const StacksListSource();

  const factory StacksListSource.newest() = _Newest;
  const factory StacksListSource.featured() = _Featured;
  const factory StacksListSource.series(String seriesId, String seriesTitle) =
      _ForSeries;
  const factory StacksListSource.user(String username, String name) = _ByUser;
  const factory StacksListSource.mine() = _Mine;
  const factory StacksListSource.saved() = _Saved;
  const factory StacksListSource.followed() = _Followed;

  String title(LocalizationService l10n);

  /// Shown above the grid, when there is something to say.
  String? subtitle(LocalizationService l10n) => null;

  /// Whether the series sort and spoiler filters apply.
  bool get filterable => false;

  /// Whether cards show the owner's view (draft / unlisted).
  bool get ownerView => false;

  /// Whether the list is the reader's own (mine, saved, followed), and so
  /// reloads when [StackStatusController.listsRevision] moves.
  bool get personal => false;

  Future<PagedList<StackSummary>> load(
    StackService service,
    int page, {
    StackSort sort = StackSort.mostVoted,
    StackSpoilerFilter spoilers = StackSpoilerFilter.exclude,
  });
}

class _Newest extends StacksListSource {
  const _Newest();
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_new');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.browse(page: page);
}

class _Featured extends StacksListSource {
  const _Featured();
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_featured');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.browse(page: page, featured: true);
}

class _ForSeries extends StacksListSource {
  final String seriesId;
  final String seriesTitle;
  const _ForSeries(this.seriesId, this.seriesTitle);
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_in_these');
  @override
  String? subtitle(LocalizationService l10n) => seriesTitle;
  @override
  bool get filterable => true;
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.forSeries(seriesId, page: page, sort: sort, spoilers: spoilers);
}

class _ByUser extends StacksListSource {
  final String username;
  final String name;
  const _ByUser(this.username, this.name);
  @override
  String title(LocalizationService l10n) =>
      l10n.translate('stacks_by_user').replaceAll('{name}', name);
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.byUser(username, page: page);
}

class _Mine extends StacksListSource {
  const _Mine();
  @override
  bool get personal => true;
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_mine');
  @override
  bool get ownerView => true;
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.mine(page: page);
}

class _Saved extends StacksListSource {
  const _Saved();
  @override
  bool get personal => true;
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_saved');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.saved(page: page);
}

class _Followed extends StacksListSource {
  const _Followed();
  @override
  bool get personal => true;
  @override
  String title(LocalizationService l10n) => l10n.translate('stacks_followed');
  @override
  Future<PagedList<StackSummary>> load(
    s,
    page, {
    sort = StackSort.mostVoted,
    spoilers = StackSpoilerFilter.exclude,
  }) => s.followed(page: page);
}
