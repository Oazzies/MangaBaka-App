import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_hub_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';

class HomeStacksRail extends StatefulWidget {
  final StackService service;
  final StackStatusController status;

  const HomeStacksRail({
    super.key,
    required this.service,
    required this.status,
  });

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
      final service = widget.service;
      var found = (await service.browse(featured: true, limit: _count)).items;
      final featured = found.isNotEmpty;
      if (!featured) found = (await service.browse(limit: _count)).items;
      if (!mounted) return;
      setState(() {
        _stacks = found;
        _featured = featured;
      });
      widget.status.request(found.map((s) => s.id));
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
