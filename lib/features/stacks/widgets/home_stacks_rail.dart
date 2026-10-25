import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_hub_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';

/// A Home rail of stacks: staff picks when there are any, otherwise the
/// newest. Its arrow opens the Stacks hub.
///
/// Like the other discovery extras it loads for itself and drops out when
/// the request fails or comes back empty.
class HomeStacksRail extends StatefulWidget {
  /// Replaces the service lookup, for tests.
  final Future<List<StackSummary>> Function()? loader;

  const HomeStacksRail({super.key, this.loader});

  @override
  State<HomeStacksRail> createState() => _HomeStacksRailState();
}

class _HomeStacksRailState extends State<HomeStacksRail> {
  static const int _count = 12;

  List<StackSummary>? _stacks;
  bool _featured = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loader = widget.loader;
      List<StackSummary> found;
      var featured = false;
      if (loader != null) {
        found = await loader();
      } else if (getIt.isRegistered<StackService>()) {
        final service = getIt<StackService>();
        found = (await service.browse(featured: true, limit: _count)).items;
        featured = found.isNotEmpty;
        if (!featured) found = (await service.browse(limit: _count)).items;
      } else {
        return;
      }
      if (!mounted) return;
      setState(() {
        _stacks = found;
        _featured = featured;
      });
      if (getIt.isRegistered<StackStatusController>()) {
        getIt<StackStatusController>().request(found.map((s) => s.id));
      }
    } catch (e) {
      LoggingService.logger.warning('Home stacks rail failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stacks = _stacks;
    if (stacks == null || stacks.isEmpty) return const SizedBox.shrink();
    final l10n = LocalizationService();
    return StacksRail(
      title: l10n.translate(
        _featured ? 'stacks_home_featured' : 'stacks_home_new',
      ),
      stacks: stacks,
      onViewAll: () => StacksHubScreen.open(context),
    );
  }
}
