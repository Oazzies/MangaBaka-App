import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

/// Owns the library's connection to the signed-in account: the entries stream,
/// the initial sync, and tearing both down on sign-out.
///
/// The screen used to hold all of this inline, with the stream set up inside a
/// `setState` callback that also kicked off an async sync. Here the state
/// transitions are explicit and the screen just listens.
class LibrarySession extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  final ProfileAuthService _auth;
  final LibraryService _library;

  /// Called with each new batch of entries, for whatever the screen needs to
  /// recompute — the stream itself is also exposed for widgets that want to
  /// build from it directly.
  final ValueChanged<List<LibraryEntry>> onEntries;

  LibrarySession({
    required this.onEntries,
    ProfileAuthService? auth,
    LibraryService? library,
  })  : _auth = auth ?? getIt<ProfileAuthService>(),
        _library = library ?? getIt<LibraryService>() {
    _loggedIn = _auth.isLoggedIn;
    _auth.addListener(_onAuthStateChanged);
    _logger.fine('Library bootstrap: loggedIn=$_loggedIn');
    if (_loggedIn) _open();
  }

  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;

  Stream<List<LibraryEntry>>? _entriesStream;
  Stream<List<LibraryEntry>>? get entriesStream => _entriesStream;

  StreamSubscription<List<LibraryEntry>>? _subscription;

  /// True when the local copy is known to be missing entries — the initial
  /// import hit its page limit and never finished.
  bool _isIncomplete = false;
  bool get isIncomplete => _isIncomplete;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthStateChanged);
    _subscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_disposed) return;
    // The auth service also notifies on every profile refresh. Only a real
    // sign-in/sign-out should rebuild the stream and re-run the sync —
    // otherwise each refresh resubscribes and re-emits the whole library.
    if (_auth.isLoggedIn == _loggedIn) return;
    _logger.info(
      'Auth state changed in LibraryScreen. LoggedIn: ${_auth.isLoggedIn}',
    );
    _loggedIn = _auth.isLoggedIn;
    if (_loggedIn) {
      _open();
    } else {
      _close();
    }
    _safeNotify();
  }

  void _open() {
    _logger.info('Setting up library entries stream and sync tasks');
    _entriesStream = _library.watchEntriesFromDb();
    _subscription?.cancel();
    _subscription = _entriesStream?.listen(onEntries);
    // Full import only on first load; later calls do an incremental catch-up.
    _runInitialSync();
  }

  void _close() {
    _entriesStream = null;
    _subscription?.cancel();
    _subscription = null;
    _isIncomplete = false;
  }

  Future<void> _runInitialSync() async {
    try {
      await _library.performInitialSyncIfNeeded();
      _logger.info('Initial sync task completed');
      final incomplete = await _library.isLibraryIncomplete();
      if (_disposed) return;
      _isIncomplete = incomplete;
      _safeNotify();
    } catch (e) {
      // The local copy is still usable; the banner and a manual retry cover
      // it, so a failed sync must not take the screen down.
      _logger.severe('Initial sync task failed: $e');
    }
  }

  /// Signs in and opens the library.
  ///
  /// Returns null on success or when the user cancelled, and an error message
  /// key when the attempt genuinely failed — a cancelled login is a choice,
  /// not something to report back.
  Future<String?> login() async {
    _logger.info('User attempting login from library screen');
    try {
      await _auth.login();
    } on AuthCancelledException {
      _logger.info('Login cancelled by user in library screen');
      return null;
    } catch (e) {
      _logger.severe('Login failed in library screen: $e');
      return 'login_failed_retry';
    }

    if (_disposed) return null;
    _logger.info('Login successful in library screen');
    // The auth listener has normally opened the session already.
    if (!_loggedIn) {
      _loggedIn = true;
      _open();
      _safeNotify();
    }
    return null;
  }

  /// A manual refresh. Failures are reported through
  /// [LibraryService.syncStatus], which raises the banner, so nothing is
  /// thrown back to the caller.
  Future<void> refresh() async {
    _logger.info('User triggered manual library refresh from screen');
    try {
      await _library.syncLibrary();
    } catch (e) {
      _logger.severe('Manual refresh failed: $e');
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }
}
