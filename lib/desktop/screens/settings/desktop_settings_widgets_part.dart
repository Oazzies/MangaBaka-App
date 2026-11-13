part of 'desktop_settings_screen.dart';

class _ScrollPage extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _ScrollPage({required this.padding, required this.child});

  @override
  State<_ScrollPage> createState() => _ScrollPageState();
}

class _ScrollPageState extends State<_ScrollPage> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      child: ListView(
        controller: _controller,
        padding: widget.padding,
        children: [widget.child],
      ),
    );
  }
}

class _ContentRatingRow extends StatelessWidget {
  final String rating;
  final LocalizationService l10n;

  const _ContentRatingRow({required this.rating, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final selected = settings.contentPreferences.contains(rating);
    final blurred = settings.blurredContentRatings.contains(rating);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DesktopHoverSurface(
        onTap: () => _toggleShown(settings, selected),
        idleColor: context.colors.surfaceRaised,
        hoverColor: context.colors.border,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                key: ValueKey(selected),
                size: 22,
                color: selected
                    ? context.colors.accent
                    : context.colors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate(rating).toUpperCase(),
                style: AppTypography.display(
                  color: selected
                      ? context.colors.text
                      : context.colors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            if (selected) ...[
              Icon(
                blurred ? Icons.blur_on : Icons.blur_off,
                size: 18,
                color: blurred
                    ? context.colors.accent
                    : context.colors.textMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.translate('blur_covers'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: blurred,
                  onChanged: (value) => _setBlurred(settings, value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleShown(SettingsManager settings, bool selected) {
    final current = List<String>.from(settings.contentPreferences);
    if (selected) {
      if (current.length > 1) current.remove(rating);
    } else if (!current.contains(rating)) {
      current.add(rating);
    }
    settings.setContentPreferences(current);
  }

  void _setBlurred(SettingsManager settings, bool blurred) {
    final current = List<String>.from(settings.blurredContentRatings);
    if (blurred) {
      if (!current.contains(rating)) current.add(rating);
    } else {
      current.remove(rating);
    }
    settings.setBlurredContentRatings(current);
  }
}

class _DesktopLogsView extends StatefulWidget {
  final LocalizationService l10n;

  const _DesktopLogsView({required this.l10n});

  @override
  State<_DesktopLogsView> createState() => _DesktopLogsViewState();
}

class _DesktopLogsViewState extends State<_DesktopLogsView> {
  final ScrollController _scrollController = ScrollController();
  List<String> _logs = [];

  String get _logsText => _logs.join('\n');

  @override
  void initState() {
    super.initState();
    _logs = List.from(LoggingService.logs);
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
    AppSnackBar.show(context, widget.l10n.translate('logs_cleared'));
  }

  void _copyLogs() {
    if (_logs.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _logsText));
    AppSnackBar.show(context, widget.l10n.translate('logs_copied'));
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
    } catch (e, st) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            DesktopPillButton(
              label: widget.l10n.translate('copy_logs'),
              icon: Icons.copy_rounded,
              onPressed: _logs.isEmpty ? null : _copyLogs,
            ),
            DesktopPillButton(
              label: widget.l10n.translate('save_logs'),
              icon: Icons.download_rounded,
              onPressed: _logs.isEmpty ? null : _saveLogs,
            ),
            DesktopPillButton(
              label: widget.l10n.translate('clear_logs'),
              icon: Icons.delete_outline_rounded,
              onPressed: _logs.isEmpty ? null : _clearLogs,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DesktopCard(
            showBorder: false,
            padding: const EdgeInsets.all(16),
            child: SizedBox.expand(
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        widget.l10n.translate('no_logs'),
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SelectableText(
                              _logs[index],
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: context.colors.text,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
