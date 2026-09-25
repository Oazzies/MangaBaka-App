import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';

import 'fixtures.dart';

/// A signed-in (or signed-out) account with no real OAuth behind it.
class FakeAuth extends ChangeNotifier with Fake implements ProfileAuthService {
  final bool signedIn;
  final MbProfile _profile = Fixtures.profile();

  FakeAuth({required this.signedIn});

  @override
  bool get isLoggedIn => signedIn;

  @override
  MbProfile? get cachedProfile => signedIn ? _profile : null;

  @override
  Future<MbProfile> fetchProfile({bool forceRefresh = false}) async => _profile;

  @override
  Future<String> getValidAccessToken() async => 'token';

  @override
  Future<http.Response> sendAuthorized(
    Future<http.Response> Function(String token) send,
  ) => send('token');

  @override
  Future<void> login() async {}

  @override
  Future<void> logout() async {}
}

/// A library that already holds [entries], with syncing as a no-op.
class FakeLibrary extends Fake implements LibraryService {
  final List<LibraryEntry> entries;

  FakeLibrary(this.entries);

  final ValueNotifier<LibrarySyncStatus> _status = ValueNotifier(
    const LibrarySyncStatus(),
  );

  @override
  ValueNotifier<LibrarySyncStatus> get syncStatus => _status;

  // Stream.multi: the screen and its search bar each listen to the stream.
  @override
  Stream<List<LibraryEntry>> watchEntriesFromDb() =>
      Stream.multi((c) => c.add(entries));

  @override
  Stream<LibraryEntry?> watchEntryFromDb(String seriesId) => Stream.multi(
    (c) => c.add(entries.where((e) => e.series.id == seriesId).firstOrNull),
  );

  @override
  Future<void> performInitialSyncIfNeeded() async {}

  @override
  Future<bool> isLibraryIncomplete() async => false;

  @override
  Future<void> syncLibrary({String? state}) async {}

  @override
  Future<void> importFullLibrary() async {}
}

/// Profile activity rails, served from the fixture library.
class FakeSnapshots extends Fake implements SnapshotService {
  final List<LibraryEntry> entries;

  FakeSnapshots(this.entries);

  @override
  List<LibraryEntry>? get cachedActivities => entries;

  @override
  Future<List<LibraryEntry>> fetchSnapshot({
    required String sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    final start = (page - 1) * limit;
    if (start >= entries.length) return const [];
    return entries.sublist(start, (start + limit).clamp(0, entries.length));
  }
}
