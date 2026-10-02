import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/screens/publisher_detail_screen.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Opens the publisher page for a publisher known only by name, as in the
/// library (which stores names, not ids).
///
/// Looks the publisher up first; if no exact match comes back, or the lookup
/// fails, the name's series are browsed instead so the tap still goes somewhere.
Future<void> openPublisherByName(BuildContext context, String name) async {
  Publisher? match;
  try {
    final found = await getIt<PublisherSearchService>().searchPublishers(
      query: name,
      limit: 5,
    );
    for (final p in found) {
      if (p.name.toLowerCase() == name.toLowerCase()) {
        match = p;
        break;
      }
    }
  } catch (e) {
    LoggingService.logger.warning('Publisher lookup for "$name" failed: $e');
  }
  if (!context.mounted) return;
  if (match != null && match.id.isNotEmpty) {
    PublisherDetailScreen.open(context, id: match.id, publisher: match);
    return;
  }
  Navigator.of(context).push(
    AppTransitions.slideRight(
      BrowseResultsScreen(sortType: name, sortBy: 'name_asc', publisher: name),
    ),
  );
}
