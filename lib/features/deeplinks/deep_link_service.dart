import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/stacks/screens/my_stacks_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_detail_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_hub_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/browse/screens/mix_screen.dart';
import 'package:mangabaka_app/features/browse/utils/browse_navigation.dart';
import 'package:mangabaka_app/features/deeplinks/deep_link_registrar.dart';
import 'package:mangabaka_app/features/deeplinks/deep_link_target.dart';
import 'package:mangabaka_app/features/home/screens/discovery_queue_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/profile/screens/statistics_screen.dart';
import 'package:mangabaka_app/features/publisher/screens/publisher_detail_screen.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Listens to incoming `https://mangabaka.org` and `mangabaka://` links,
/// then routes the user to the matching screen inside the app. What each URL
/// shape maps to lives in [DeepLinkTarget.parse].
///
/// Platform registration:
///   Android  — intent filters in AndroidManifest.xml
///   iOS      — CFBundleURLSchemes in ios/Runner/Info.plist
///   macOS    — CFBundleURLTypes in macos/Runner/Info.plist
///   Windows  — `mangabaka://` registered in HKCU\Software\Classes at init
///   Linux    — `mangabaka://` registered via a .desktop file at init
///
/// Only Android claims `https://mangabaka.org` links (and only once the site
/// serves a matching assetlinks.json); every other platform receives just the
/// `mangabaka://` scheme.
///
/// The service respects the [SettingsManager.openLinksInApp] toggle; links
/// that arrive while the toggle is off are silently ignored. A link that lands
/// before the app shell is on screen (a cold start) waits for it.
class DeepLinkService {
  static final _logger = LoggingService.logger;
  static const _scheme = 'mangabaka';

  /// How long a link waits for the app shell before it is dropped.
  static const _readyPoll = Duration(milliseconds: 500);
  static const _readyAttempts = 60;

  /// The settings string describing what the toggle covers on this platform.
  static String get subtextKey =>
      Platform.isAndroid ? 'open_links_subtext' : 'open_links_subtext_scheme';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Timer? _readyTimer;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Register the custom protocol with the OS on platforms that need it.
    if (Platform.isWindows) await DeepLinkRegistrar.registerWindows(_scheme);
    if (Platform.isLinux) await DeepLinkRegistrar.registerLinux(_scheme);

    // Handle the link that cold-started the app (if any).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      _logger.warning('DeepLinkService: failed to read initial link: $e');
    }

    // Handle subsequent links while the app is running.
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (e) => _logger.warning('DeepLinkService: link stream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _readyTimer?.cancel();
    _readyTimer = null;
  }

  // ─── Routing ─────────────────────────────────────────────────────────────

  void _handle(Uri uri) {
    if (!SettingsManager().openLinksInApp) {
      _logger.fine('DeepLinkService: ignoring link (toggle off): $uri');
      return;
    }
    _logger.info('DeepLinkService: handling link: $uri');

    final target = DeepLinkTarget.parse(uri);
    if (target == null) {
      _logger.fine('DeepLinkService: no handler for link: $uri');
      _whenReady(
        (ctx) => AppSnackBar.show(
          ctx,
          LocalizationService().translate('deep_link_unsupported'),
          isError: true,
        ),
      );
      return;
    }
    _whenReady((ctx) => _open(ctx, target));
  }

  bool get _shellReady =>
      MainScreen.mainScreenKey.currentState != null ||
      DesktopShell.current != null;

  /// Runs [action] once the tab shell is mounted. A cold start delivers the
  /// link while the splash or onboarding is still up, when the navigator
  /// exists but there is no shell to land in.
  void _whenReady(void Function(BuildContext context) action) {
    var attempts = 0;
    void attempt() {
      final context = AppConstants.navigatorKey.currentContext;
      if (context != null && context.mounted && _shellReady) {
        _readyTimer = null;
        action(context);
        return;
      }
      if (++attempts >= _readyAttempts) {
        _readyTimer = null;
        _logger.warning(
          'DeepLinkService: app never became ready; link dropped',
        );
        return;
      }
      _readyTimer = Timer(_readyPoll, attempt);
    }

    _readyTimer?.cancel(); // a newer link replaces one still waiting
    attempt();
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _open(BuildContext context, DeepLinkTarget target) {
    switch (target) {
      case SeriesTarget(:final id):
        _openSeries(id);
      case PublisherTarget(:final id):
        PublisherDetailScreen.open(context, id: id);
      case PublisherListTarget():
        BrowseNavigation.showPublishers(context);
      case TabTarget(:final index):
        Navigator.of(context).popUntil((route) => route.isFirst);
        MainScreen.setTabIndex(index);
      case SearchTarget(:final query, :final filters):
        BrowseNavigation.search(context, query, filters);
      case DiscoverTarget():
        Navigator.of(
          context,
        ).push(AppTransitions.slideRight(const DiscoveryQueueScreen()));
      case MixTarget():
        Navigator.of(
          context,
        ).push(AppTransitions.slideRight(const MixScreen()));
      case StatsTarget():
        Navigator.of(
          context,
        ).push(AppTransitions.slideRight(const StatisticsScreen()));
      case StackHubTarget():
        StacksHubScreen.open(context);
      case StackListTarget():
        StacksListScreen.open(context, const StacksListSource.newest());
      case StackTarget(:final id):
        StackDetailScreen.open(context, id: id);
      case MyStacksTarget():
        MyStacksScreen.open(context);
    }
  }

  Future<void> _openSeries(String seriesId) async {
    _logger.info('DeepLinkService: opening series $seriesId');
    final context = AppConstants.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _logger.warning('DeepLinkService: no context available for navigation');
      return;
    }

    try {
      final series = await getIt<SeriesService>().fetchSeries(seriesId);
      if (!context.mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(AppTransitions.slideUp(SeriesDetailScreen(series: series)));
    } catch (e) {
      _logger.warning('DeepLinkService: failed to open series $seriesId: $e');
      final ctx = AppConstants.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        AppSnackBar.show(
          ctx,
          LocalizationService().translate('deep_link_failed'),
          isError: true,
        );
      }
    }
  }
}
