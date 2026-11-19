part of 'progress_update_dialog.dart';

class _ProgressDialogHeader extends StatelessWidget {
  final String title;
  final Widget? totalLine;

  const _ProgressDialogHeader({required this.title, required this.totalLine});

  @override
  Widget build(BuildContext context) {
    final totalLine = this.totalLine;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: context.colors.accent,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 18,
                ),
              ),
              if (totalLine != null) ...[const SizedBox(height: 2), totalLine],
            ],
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: context.colors.text, size: 20),
        ),
      ),
    );
  }
}
