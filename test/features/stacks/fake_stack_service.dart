import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';

import 'stack_fixtures.dart';

class FakeStacksService extends Fake implements StackService {
  StackDetail detail = StackDetail.fromJson(stackDetailJson());
  List<MySeriesStack> mineForSeries = const [];
  final List<String> calls = [];

  PagedList<StackSummary> _page(int n) => PagedList([
    for (var i = 0; i < n; i++)
      StackSummary.fromJson(stackSummaryJson(id: 100 + i)),
  ], hasNext: false);

  @override
  Future<PagedList<StackSummary>> browse({
    int page = 1,
    int limit = 24,
    bool featured = false,
  }) async => featured ? _page(0) : _page(3);

  @override
  Future<PagedList<StackSummary>> mine({int page = 1, int limit = 24}) async =>
      _page(2);
  @override
  Future<PagedList<StackSummary>> saved({int page = 1, int limit = 24}) async =>
      _page(0);
  @override
  Future<PagedList<StackSummary>> followed({
    int page = 1,
    int limit = 24,
  }) async => _page(1);

  @override
  Future<StackDetail> fetch(int id) async => detail;

  @override
  Future<StackDetail> fetchForEdit(int id) async =>
      StackDetail.fromJson(ownerStackDetailJson(id: id));

  @override
  Future<Map<int, StackStatus>> status(Iterable<int> ids) async => {
    for (final id in ids)
      id: StackStatus(id: id, libraryCount: 1, voteCount: 9),
  };

  @override
  Future<StackStatus> vote(int id) async {
    calls.add('vote $id');
    return StackStatus(id: id, hasVoted: true, voteCount: 10);
  }

  @override
  Future<List<MySeriesStack>> myStacksForSeries(String seriesId) async =>
      mineForSeries;

  @override
  Future<int> addEntry(
    int stackId,
    String seriesId, {
    String? note,
    int? rank,
    String? contentRating,
  }) async {
    calls.add('add $seriesId to $stackId');
    return 3;
  }

  @override
  Future<StackDetail> create(StackDraft draft) async {
    calls.add('create ${draft.title}');
    return StackDetail.fromJson(ownerStackDetailJson(id: 99));
  }
}
