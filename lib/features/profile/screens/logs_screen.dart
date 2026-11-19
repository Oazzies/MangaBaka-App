import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<String> _logs = [];

  String get _logsText => _logs.join('\n');

  @override
  void initState() {
    super.initState();
    _logs = LoggingService.logs;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _clearLogs() {
    LoggingService.clearLogs();
    setState(() => _logs = []);
    AppSnackBar.show(context, LocalizationService().translate('logs_cleared'));
  }

  void _copyLogs() {
    if (_logs.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _logsText));
    AppSnackBar.show(context, LocalizationService().translate('logs_copied'));
  }

  Future<void> _saveLogs() async {
    if (_logs.isEmpty) return;
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/mangabaka_logs.txt');
      await file.writeAsString(_logsText);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: LocalizationService().translate('share_subject_logs'),
        ),
      );
    } catch (e, st) {
      // File I/O or the share sheet; either way only the export failed.
      LoggingService.logger.warning('Failed to save logs', e, st);
      if (mounted) {
        AppSnackBar.show(
          context,
          LocalizationService().translate('logs_save_failed'),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.translate('logs').toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          WidgetUtils.tooltip(
            message: l10n.translate('clear_logs'),
            child: IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.colors.text,
              ),
              onPressed: _clearLogs,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                ),
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('no_logs'),
                          style: AppTypography.sans(
                            color: context.colors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              _logs[index],
                              style: TextStyle(
                                color: context.colors.text.withValues(
                                  alpha: 0.8,
                                ),
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: MbSecondaryButton(
                      label: l10n.translate('copy_logs'),
                      icon: Icons.copy_rounded,
                      onPressed: _logs.isEmpty ? null : _copyLogs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MbPrimaryButton(
                      label: l10n.translate('save_logs'),
                      icon: Icons.download_rounded,
                      onPressed: _logs.isEmpty ? null : _saveLogs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
