part of 'desktop_filter_panel.dart';

class _MiniToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      selected: active,
      selectedColor: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.all(4),
      child: Icon(
        icon,
        size: 17,
        color: active ? color : context.colors.textMuted,
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onRemove,
      idleColor: context.colors.accent.withValues(alpha: 0.18),
      hoverColor: context.colors.error.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.close_rounded, size: 14, color: context.colors.text),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.display(
          color: context.colors.accent,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

/// A small filled search field used inside panels.
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.sans(color: context.colors.text, fontSize: 13.5),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 13.5,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: context.colors.textMuted,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: context.colors.textMuted,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.colors.accent, width: 1.2),
        ),
      ),
    );
  }
}

/// A one-line field that hands back the trimmed text on submit and clears.
class _PublisherField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSubmit;

  const _PublisherField({required this.hint, required this.onSubmit});

  @override
  State<_PublisherField> createState() => _PublisherFieldState();
}

class _PublisherFieldState extends State<_PublisherField> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_text.text.trim());
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: _text,
      onSubmitted: (_) => _submit(),
      style: AppTypography.sans(color: c.text, fontSize: 13),
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: _submit,
        ),
      ),
    );
  }
}
