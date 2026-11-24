import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';

/// Returns null on success, otherwise an l10n key shown under the field.
typedef LibraryListSubmit =
    Future<String?> Function(String name, bool isPrivate);

/// A page on phones, a dialog elsewhere; closes itself once [onSubmit] succeeds.
Future<void> showLibraryListForm(
  BuildContext context, {
  LibraryList? editing,
  required LibraryListSubmit onSubmit,
}) => showAdaptiveForm<void>(
  context: context,
  title: LocalizationService().translate(
    editing == null ? 'lists_new' : 'lists_edit',
  ),
  constraints: const BoxConstraints(maxWidth: 480),
  builder: (_) => LibraryListForm(editing: editing, onSubmit: onSubmit),
);

class LibraryListForm extends StatefulWidget {
  final LibraryList? editing;
  final LibraryListSubmit onSubmit;

  const LibraryListForm({super.key, this.editing, required this.onSubmit});

  @override
  State<LibraryListForm> createState() => _LibraryListFormState();
}

class _LibraryListFormState extends State<LibraryListForm> {
  late final TextEditingController _name = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.editing?.name ?? '',
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: widget.editing?.name.length ?? 0,
      ),
    ),
  );
  late bool _private = widget.editing?.isPrivate ?? false;
  final LocalizationService _l10n = LocalizationService();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(_name.text, _private);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final page = AdaptiveFormPage.isPage(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!page) ...[
            Text(
              _l10n
                  .translate(
                    widget.editing == null ? 'lists_new' : 'lists_edit',
                  )
                  .toUpperCase(),
              style: AppTypography.display(color: c.text, fontSize: 18),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            key: const ValueKey('list_name_field'),
            controller: _name,
            autofocus: true,
            maxLength: LibraryListRules.nameMax,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: AppTypography.sans(color: c.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: _l10n.translate('lists_name_hint'),
              errorText: _error == null ? null : _l10n.translate(_error!),
              errorMaxLines: 3,
              filled: true,
              fillColor: c.surfaceRaised,
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: c.accent, width: 1.5),
              ),
              errorBorder: border.copyWith(
                borderSide: BorderSide(color: c.error, width: 1.5),
              ),
              focusedErrorBorder: border.copyWith(
                borderSide: BorderSide(color: c.error, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _PrivacySwitch(
            value: _private,
            label: _l10n.translate('lists_private'),
            onChanged: _busy ? null : (v) => setState(() => _private = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MbSecondaryButton(
                  key: const ValueKey('list_form_cancel'),
                  label: _l10n.translate('cancel'),
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MbPrimaryButton(
                  key: const ValueKey('list_form_save'),
                  label: _l10n.translate(
                    widget.editing == null ? 'lists_create' : 'save',
                  ),
                  busy: _busy,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;

  const _PrivacySwitch({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Icon(
              value ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 20,
              color: value ? c.accent : c.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.sans(
                  color: c.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
