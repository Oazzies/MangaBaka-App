import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

class LibrarySession extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  final ProfileAuthService _auth;
  final LibraryService _library;

  final ValueChanged<List<LibraryEntry>> onEntries;

  LibrarySession({
    required this.onEntries,
    ProfileAuthService? auth,
    LibraryService? library,
  }) : _auth = auth ?? getIt<ProfileAuthService>(),
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
    // The auth service also notifies on profile refreshes; only a real sign-in/out resubscribes.
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
    } catch (e, st) {
      // The local copy stays usable and the banner offers a retry, so this must not throw.
      _logger.severe('Initial sync task failed', e, st);
    }
  }

  /// Returns an error message key on failure; null on success or cancel (a choice, not an error).
  Future<String?> login() async {
    _logger.info('User attempting login from library screen');
    try {
      await _auth.login();
    } on AuthCancelledException {
      _logger.info('Login cancelled by user in library screen');
      return null;
    } catch (e, st) {
      _logger.severe('Login failed in library screen', e, st);
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

  Future<void> refresh() async {
    _logger.info('User triggered manual library refresh from screen');
    try {
      await _library.syncLibrary(deep: true);
    } catch (e, st) {
      // Reported to the user through the sync status banner.
      _logger.severe('Manual refresh failed', e, st);
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }
}
