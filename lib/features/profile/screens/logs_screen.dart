import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocalizationService().translate('logs_cleared'))),
    );
  }

  void _copyLogs() {
    if (_logs.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocalizationService().translate('logs_copied'))),
    );
  }

  Future<void> _saveLogs() async {
    if (_logs.isEmpty) return;
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/mangabaka_logs.txt');
      await file.writeAsString(_logsText);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'MangaBaka Logs'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save logs: $e')),
        );
      }
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.translate('logs'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          WidgetUtils.tooltip(
            message: l10n.translate('clear_logs'),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: AppConstants.textColor),
              onPressed: _clearLogs,
            ),
          ),
        ],
      ),
      body: WidgetUtils.responsiveConstraint(
        Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryBackground,
                  borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                ),
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No logs recorded yet',
                          style: TextStyle(color: AppConstants.textMutedColor),
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
                                color: AppConstants.textColor.withValues(alpha: 0.8),
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: l10n.translate('copy_logs'),
                      icon: Icons.copy,
                      onPressed: _logs.isEmpty ? null : _copyLogs,
                      backgroundColor: AppConstants.tertiaryBackground,
                      foregroundColor: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      label: l10n.translate('save_logs'),
                      icon: Icons.share,
                      onPressed: _logs.isEmpty ? null : _saveLogs,
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: AppConstants.primaryBackground,
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
