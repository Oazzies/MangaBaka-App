import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';

import 'stack_fixtures.dart';

class _FakeAuth extends ChangeNotifier with Fake implements ProfileAuthService {
  bool loggedIn = true;
  @override
  bool get isLoggedIn => loggedIn;
  @override
  bool get hasStackScopes => loggedIn;
}

class _FakeStacks extends Fake implements StackService {
  final List<String> calls = [];
  StackDraft? lastDraft;
  String? lastToken;
  Object? failNext;
  int statusCalls = 0;

  Never _fail() {
    final e = failNext!;
    failNext = null;
    throw e;
  }

  @override
  Future<Map<int, StackStatus>> status(Iterable<int> ids) async {
    statusCalls++;
    return {for (final id in ids) id: StackStatus(id: id, voteCount: 5)};
  }

  @override
  Future<StackStatus> vote(int id) async {
    calls.add('vote $id');
    if (failNext != null) _fail();
    return StackStatus(id: id, hasVoted: true, voteCount: 6);
  }

  @override
  Future<StackStatus> follow(int id) async {
    calls.add('follow $id');
    return StackStatus(
      id: id,
      hasFollowed: true,
      hasSaved: true,
      followCount: 1,
    );
  }

  @override
  Future<StackDetail> fetchForEdit(int id) async {
    calls.add('fetchForEdit $id');
    return StackDetail.fromJson(ownerStackDetailJson(id: id));
  }

  @override
  Future<StackDetail> create(StackDraft draft) async {
    calls.add('create');
    lastDraft = draft;
    return StackDetail.fromJson(ownerStackDetailJson(id: 99));
  }

  @override
  Future<StackVisibility> setVisibility(int id, StackVisibility v) async {
    calls.add('visibility $id ${v.name}');
    return v;
  }

  @override
  Future<StackDetail> update(int id, StackDraft draft, String token) async {
    calls.add('update $id');
    lastDraft = draft;
    lastToken = token;
    if (failNext != null) _fail();
    return StackDetail.fromJson(ownerStackDetailJson(id: id));
  }
}

Series _series(int id, {String rating = 'safe'}) =>
    Series.fromJson({...seriesJson(id, 'S$id'), 'content_rating': rating});

void main() {
  late _FakeStacks service;
  late _FakeAuth auth;

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    service = _FakeStacks();
    auth = _FakeAuth();
    getIt.registerSingleton<ProfileAuthService>(auth);
    getIt.registerSingleton<StackService>(service);
    getIt.registerSingleton<StackStatusController>(
      StackStatusController(service: service, auth: auth),
    );
  });

  tearDown(resetServiceLocator);

  group('StackStatusController', () {
    test('batches requests made together into one status call', () async {
      final c = getIt<StackStatusController>();
      c.request([1, 2]);
      c.request([2, 3]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(service.statusCalls, 1);
      expect(c.of(3)?.voteCount, 5);
    });

    test('a vote moves at once and takes the server answer', () async {
      final c = getIt<StackStatusController>();
      final pending = c.toggle(
        7,
        StackReaction.vote,
        fallback: const StackStatus(id: 7, voteCount: 5),
      );
      expect(c.of(7)?.hasVoted, isTrue);
      expect(c.of(7)?.voteCount, 6);
      expect(c.isBusy(7), isTrue);
      await pending;
      expect(c.isBusy(7), isFalse);
      expect(service.calls, ['vote 7']);
    });

    test('a refused vote rolls back and rethrows', () async {
      final c = getIt<StackStatusController>();
      service.failNext = StackApiException(
        message: 'x',
        statusCode: 429,
        code: StackErrorCode.rateLimited,
      );
      await expectLater(
        c.toggle(7, StackReaction.vote, fallback: const StackStatus(id: 7)),
        throwsA(isA<StackApiException>()),
      );
      expect(c.of(7)?.hasVoted, isFalse);
    });

    test('following bumps the lists revision; voting does not', () async {
      final c = getIt<StackStatusController>();
      final before = c.listsRevision.value;
      await c.toggle(1, StackReaction.vote);
      expect(c.listsRevision.value, before);
      await c.toggle(2, StackReaction.follow);
      expect(c.listsRevision.value, before + 1);
      expect(c.of(2)?.hasSaved, isTrue);
    });

    test('signing out forgets every status', () async {
      final c = getIt<StackStatusController>();
      await c.toggle(1, StackReaction.vote);
      auth.loggedIn = false;
      auth.notifyListeners();
      expect(c.of(1), isNull);
    });
  });

  group('StackEditorController', () {
    test('a new stack needs a title, and publishing needs 5 series', () {
      final c = StackEditorController(service: service);
      expect(c.problems, contains(StackEditorProblem.titleMissing));
      c.title.text = 'Best';
      expect(c.problems, isEmpty);
      c.setVisibility(StackVisibility.public);
      expect(c.problems, [StackEditorProblem.tooFewToPublish]);
      for (var i = 0; i < 5; i++) {
        expect(c.add(_series(i + 1)), isTrue);
      }
      expect(c.problems, isEmpty);
      expect(c.add(_series(1)), isFalse, reason: 'already in the stack');
      c.dispose();
    });

    test('reorder follows the onReorderItem convention', () {
      final c = StackEditorController(service: service);
      for (final id in [1, 2, 3]) {
        c.add(_series(id));
      }
      c.reorder(0, 2);
      expect(c.entries.map((e) => e.seriesId), ['2', '3', '1']);
      c.move(2, -1);
      expect(c.entries.map((e) => e.seriesId), ['2', '1', '3']);
      expect(c.dirty, isTrue);
      c.dispose();
    });

    test(
      'creating a public stack creates a draft, then publishes it',
      () async {
        final c = StackEditorController(service: service);
        c.title.text = 'Five';
        for (var i = 0; i < 5; i++) {
          c.add(_series(i + 1));
        }
        c.setNote(0, 'why');
        c.setVisibility(StackVisibility.public);
        await c.save();
        expect(service.calls, ['create', 'visibility 99 public']);
        expect(service.lastDraft!.entries.first.note, 'why');
        expect(c.dirty, isFalse);
        c.dispose();
      },
    );

    test('editing loads the token and sends it back', () async {
      final c = StackEditorController(stackId: 7, service: service);
      await c.load();
      expect(c.title.text, 'Stack 7');
      expect(c.isSpoilerLocked, isTrue);
      expect(c.dirty, isFalse);
      c.setSpoiler(false);
      expect(c.isSpoiler, isFalse, reason: 'fixture starts not spoiler');
      c.title.text = 'Renamed';
      await c.save();
      expect(service.lastToken, 'tok-1');
      expect(service.lastDraft!.title, 'Renamed');
      c.dispose();
    });

    test('overwrite after a stale token re-reads the token first', () async {
      final c = StackEditorController(stackId: 7, service: service);
      await c.load();
      service.failNext = StackApiException(
        message: 'x',
        statusCode: 409,
        code: StackErrorCode.staleToken,
      );
      await expectLater(c.save(), throwsA(isA<StackApiException>()));
      service.calls.clear();
      await c.save(overwrite: true);
      expect(service.calls, ['fetchForEdit 7', 'update 7']);
      c.dispose();
    });

    test('warns when too many series are rated above the stack', () {
      final c = StackEditorController(service: service);
      c.add(_series(1));
      c.add(_series(2, rating: 'erotica'));
      expect(c.ratingTooLow, isTrue);
      expect(c.suggestedRating, 'erotica');
      c.setRating('erotica');
      expect(c.ratingTooLow, isFalse);
      c.dispose();
    });

    test('a moderator minimum rating blocks a lower one', () async {
      final c = StackEditorController(stackId: 7, service: service);
      await c.load();
      c.setRating('safe');
      expect(c.problems, contains(StackEditorProblem.ratingBelowMinimum));
      c.dispose();
    });
  });
}
