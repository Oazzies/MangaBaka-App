part of 'desktop_upcoming_rail.dart';

class _DateGroup {
  final DateTime? date;
  final List<SeriesWork> works;

  const _DateGroup(this.date, this.works);
}

/// Day heading: a big "25 SEP" with the weekday and distance beside it.
class _DateHeader extends StatelessWidget {
  final DateTime? date;
  final bool first;
  final LocalizationService l10n;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const _DateHeader({
    required this.date,
    required this.first,
    required this.l10n,
    required this.isCollapsed,
    required this.onToggle,
  });

  String _relative(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = d.difference(today).inDays;
    if (days == 0) return l10n.translate('upcoming_today');
    if (days == 1) return l10n.translate('upcoming_tomorrow');
    return DateFormat('EEEE').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final d = date;
    final isToday =
        d != null && _relative(d) == l10n.translate('upcoming_today');
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, first ? 12 : 22, 4, 10),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isCollapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 20,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  d == null
                      ? l10n.translate('upcoming_date_tba').toUpperCase()
                      : DateFormat('d MMM').format(d).toUpperCase(),
                  style: AppTypography.display(
                    color: isToday
                        ? context.colors.accent
                        : context.colors.text,
                    fontSize: d == null ? 14 : 22,
                    height: 1,
                  ),
                ),
                if (d != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _relative(d).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoLabel(
                        color: context.colors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
