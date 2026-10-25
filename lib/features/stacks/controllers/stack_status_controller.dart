import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';

/// What a reader can do to a stack from its card or page.
enum StackReaction { vote, save, follow }

/// The signed-in reader's vote / save / follow state for every stack on
/// screen, shared so a stack's buttons agree wherever it is shown.
///
/// Cards ask for their ids with [request]; requests made in the same frame
/// go out as one batched `GET /v2/my/stacks/status`. Toggles move the state
/// immediately and roll back if the server refuses.
class StackStatusController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  final StackService? _serviceOverride;
  final ProfileAuthService? _authOverride;

  StackStatusController({StackService? service, ProfileAuthService? auth})
    : _serviceOverride = service,
      _authOverride = auth {
    _authRef = _auth..addListener(_onAuthChanged);
    _wasLoggedIn = _authRef.isLoggedIn;
  }

  StackService get _service => _serviceOverride ?? getIt<StackService>();
  ProfileAuthService get _auth => _authOverride ?? getIt<ProfileAuthService>();

  late final ProfileAuthService _authRef;
  final Map<int, StackStatus> _status = {};
  final Set<int> _queued = {};
  final Set<int> _inFlight = {};
  final Set<int> _busy = {};
  bool _flushScheduled = false;
  bool _wasLoggedIn = false;

  /// Whether statuses can be read at all: signed in with the stack scopes.
  bool get available => _auth.hasStackScopes;

  StackStatus? of(int id) => _status[id];

  /// Whether a toggle for [id] is waiting on the server.
  bool isBusy(int id) => _busy.contains(id);

  /// Asks for the status of [ids] that are not known yet.
  void request(Iterable<int> ids) {
    if (!available) return;
    var added = false;
    for (final id in ids) {
      if (_status.containsKey(id) || _inFlight.contains(id)) continue;
      added = _queued.add(id) || added;
    }
    if (!added || _flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(_flush);
  }

  /// Re-reads [ids] even when known (after an edit, or a pull to refresh).
  Future<void> refresh(Iterable<int> ids) async {
    if (!available) return;
    final list = ids.toList();
    if (list.isEmpty) return;
    try {
      _status.addAll(await _service.status(list));
      notifyListeners();
    } catch (e) {
      _logger.fine('Stack status refresh failed: $e');
    }
  }

  Future<void> _flush() async {
    _flushScheduled = false;
    final ids = _queued.toList();
    _queued.clear();
    if (ids.isEmpty) return;
    _inFlight.addAll(ids);
    try {
      _status.addAll(await _service.status(ids));
      notifyListeners();
    } catch (e) {
      // A missing status just leaves the buttons on the listing's counts.
      _logger.fine('Stack status load failed: $e');
    } finally {
      _inFlight.removeAll(ids);
    }
  }

  /// Toggles [reaction] on stack [id]. [fallback] seeds the state when the
  /// status has not loaded (counts from the listing). Rethrows the server's
  /// refusal after rolling back, for the caller to report.
  Future<void> toggle(
    int id,
    StackReaction reaction, {
    StackStatus? fallback,
  }) async {
    if (_busy.contains(id)) return;
    final before = _status[id] ?? fallback ?? StackStatus(id: id);
    final after = switch (reaction) {
      StackReaction.vote => before.toggledVote(),
      StackReaction.save => before.toggledSave(),
      StackReaction.follow => before.toggledFollow(),
    };
    _status[id] = after;
    _busy.add(id);
    notifyListeners();

    try {
      final result = await switch (reaction) {
        StackReaction.vote =>
          before.hasVoted ? _service.unvote(id) : _service.vote(id),
        StackReaction.save =>
          before.hasSaved ? _service.unsave(id) : _service.save(id),
        StackReaction.follow =>
          before.hasFollowed ? _service.unfollow(id) : _service.follow(id),
      };
      if (result.id == id) _status[id] = result;
      if (reaction != StackReaction.vote) markListsChanged();
    } catch (e) {
      _status[id] = before;
      rethrow;
    } finally {
      _busy.remove(id);
      notifyListeners();
    }
  }

  /// Bumped whenever the reader's own lists change: a stack created, edited
  /// or deleted, or one saved or followed. "My stacks", "Saved" and
  /// "Followed" listen to it and reload.
  final ValueNotifier<int> listsRevision = ValueNotifier(0);

  /// Says the reader's stacks changed (after a create, edit or delete).
  void markListsChanged() => listsRevision.value++;

  void _onAuthChanged() {
    // Statuses belong to an account: drop them whenever one signs in or out.
    final loggedIn = _authRef.isLoggedIn;
    if (loggedIn != _wasLoggedIn) clear();
    _wasLoggedIn = loggedIn;
  }

  /// Forgets every status (on sign-out, or another account signing in).
  void clear() {
    if (_status.isEmpty) return;
    _status.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _authRef.removeListener(_onAuthChanged);
    listsRevision.dispose();
    super.dispose();
  }
}
