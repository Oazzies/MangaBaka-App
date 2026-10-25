import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';

import 'stack_fixtures.dart';

void main() {
  group('StackSummary', () {
    test('reads a listing row', () {
      final s = StackSummary.fromJson(stackSummaryJson(id: 35));
      expect(s.id, 35);
      expect(s.title, 'Stack 35');
      expect(s.owner.display, 'angelmastiff');
      expect(s.owner.username, 'angelmastiff');
      expect(s.visibility, StackVisibility.public);
      expect(s.kind, StackKind.personal);
      expect(s.entryCount, 6);
      expect(s.voteCount, 2);
      expect(s.covers, hasLength(2));
      expect(s.covers.first.url, contains('x350'));
      expect(s.covers.first.seriesId, '5072');
      expect(s.updatedAt, isNotNull);
    });

    test('a deleted owner has no username', () {
      final json = stackSummaryJson()
        ..['owner'] = {'name': 'Gone', 'username': null};
      final s = StackSummary.fromJson(json);
      expect(s.owner.username, isNull);
      expect(s.owner.display, 'Gone');
    });

    test('rejects a row without an id', () {
      expect(
        () => StackSummary.fromJson({'title': 'x'}),
        throwsFormatException,
      );
    });
  });

  group('StackDetail', () {
    test('reads public entries and placeholders, in rank order', () {
      final d = StackDetail.fromJson(stackDetailJson());
      expect(d.description, contains('Strong'));
      expect(d.entries.map((e) => e.rank), [1, 2, 3]);
      expect(d.entries[0].series?.title, 'Mushoku Tensei');
      expect(d.entries[0].note, 'Return by death');
      expect(d.entries[1].isPlaceholder, isTrue);
      expect(d.entries[1].issue, StackEntryIssue.merged);
      expect(d.entries[2].issue, StackEntryIssue.deleted);
      expect(d.liveEntries, hasLength(1));
      expect(d.token, isNull);
    });

    test('reads the owner shape: issue object and token', () {
      final d = StackDetail.fromJson(ownerStackDetailJson());
      expect(d.token, 'tok-1');
      expect(d.isSpoilerLocked, isTrue);
      expect(d.minContentRating, 'suggestive');
      final merged = d.entries.firstWhere((e) => e.issue != null);
      expect(merged.issue, StackEntryIssue.merged);
      expect(merged.mergedWith, '999');
      expect(merged.seriesId, '42');
    });

    test('a draft from an owner stack keeps every entry id', () {
      final d = StackDetail.fromJson(ownerStackDetailJson());
      final draft = StackDraft.fromDetail(d);
      expect(draft.entries.map((e) => e.seriesId), ['217', '42']);
      final body = draft.toUpdateJson('tok-1');
      expect(body['token'], 'tok-1');
      expect(body['visibility'], 'draft');
      expect((body['entries'] as List).first, {'series_id': 217, 'note': 'Hi'});
    });
  });

  group('StackStatus toggles', () {
    const base = StackStatus(id: 1, voteCount: 3, saveCount: 2, followCount: 1);

    test('vote adds and removes one', () {
      final voted = base.toggledVote();
      expect(voted.hasVoted, isTrue);
      expect(voted.voteCount, 4);
      expect(voted.toggledVote().voteCount, 3);
    });

    test('follow also saves; unfollow keeps the save', () {
      final followed = base.toggledFollow();
      expect(followed.hasFollowed, isTrue);
      expect(followed.hasSaved, isTrue);
      expect(followed.saveCount, 3);
      final unfollowed = followed.toggledFollow();
      expect(unfollowed.hasFollowed, isFalse);
      expect(unfollowed.hasSaved, isTrue);
    });

    test('unsave also unfollows', () {
      final both = base.toggledFollow();
      final unsaved = both.toggledSave();
      expect(unsaved.hasSaved, isFalse);
      expect(unsaved.hasFollowed, isFalse);
      expect(unsaved.followCount, 1);
    });
  });

  test('MySeriesStack reads rank and can_add', () {
    final s = MySeriesStack.fromJson({
      'id': 4,
      'title': 'Mine',
      'visibility': 'unlisted',
      'entry_count': 7,
      'rank': 2,
      'can_add': false,
    });
    expect(s.contains, isTrue);
    expect(s.canAdd, isFalse);
    expect(s.visibility, StackVisibility.unlisted);
  });

  test('stackMarkdown flattens block markdown to inline', () {
    expect(
      stackMarkdown('# Strong Lead\nYes.\n---\n- one\n> quoted'),
      '**Strong Lead**\nYes.\n———\n•  one\nquoted',
    );
  });
}
