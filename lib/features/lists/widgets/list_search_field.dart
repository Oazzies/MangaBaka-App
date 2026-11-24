import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ListSearchField extends StatefulWidget {
  final String hint;
  final String initial;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const ListSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initial = '',
    this.autofocus = false,
  });

  @override
  State<ListSearchField> createState() => _ListSearchFieldState();
}

class _ListSearchFieldState extends State<ListSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _clear() {
    _text.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _text,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {});
        },
        style: AppTypography.sans(color: c.text, fontSize: 14.5),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          hintStyle: AppTypography.sans(color: c.textMuted, fontSize: 14.5),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.textMuted),
          suffixIcon: _text.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                  onPressed: _clear,
                ),
          filled: true,
          fillColor: c.surfaceRaised,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: c.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
