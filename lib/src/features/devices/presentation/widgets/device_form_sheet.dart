import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/errors.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/notice.dart';
import '../../domain/device.dart';

typedef DeviceSubmit = Future<void> Function(String name, Map<String, Object?> data);

/// Create or edit a device: a name plus any number of key/value attributes.
class DeviceFormSheet extends StatefulWidget {
  const DeviceFormSheet({super.key, this.device, required this.onSubmit});

  final Device? device;
  final DeviceSubmit onSubmit;

  @override
  State<DeviceFormSheet> createState() => _DeviceFormSheetState();
}

class _DeviceFormSheetState extends State<DeviceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.device?.name);
  late final List<(TextEditingController, TextEditingController)> _fields = [
    for (final e in widget.device?.data.entries ?? const <MapEntry<String, Object?>>[])
      (TextEditingController(text: e.key), TextEditingController(text: Device.formatValue(e.value))),
  ];
  bool _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (_fields.isEmpty) _addField();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final (k, v) in _fields) {
      k.dispose();
      v.dispose();
    }
    super.dispose();
  }

  void _addField() => setState(() => _fields.add((TextEditingController(), TextEditingController())));

  void _removeField(int index) {
    final (k, v) = _fields.removeAt(index);
    k.dispose();
    v.dispose();
    setState(() {});
  }

  /// Numbers typed into a value field are sent as numbers, the way the
  /// sample objects store them.
  static Object _parse(String raw) {
    final text = raw.trim();
    return int.tryParse(text) ?? double.tryParse(text) ?? text;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, Object?>{
      for (final (k, v) in _fields)
        if (k.text.trim().isNotEmpty) k.text.trim(): _parse(v.text),
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_name.text.trim(), data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
        children: [
          Text(widget.device == null ? l10n.addDevice : l10n.editDevice, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Insets.lg),
          LabeledField(
            label: l10n.deviceNameLabel,
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            hintText: 'Pixel 9, 256 GB',
            validator: (v) {
              final e = validateRequired(v);
              return e == null ? null : describeFieldError(e, l10n);
            },
          ),
          const SizedBox(height: Insets.lg),
          for (final (i, (key, value)) in _fields.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: LabeledField(
                      label: l10n.fieldKeyLabel,
                      controller: key,
                      hintText: 'color',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: LabeledField(
                      label: l10n.fieldValueLabel,
                      controller: value,
                      hintText: 'Black',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.removeField,
                    onPressed: () => _removeField(i),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addField,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.addField),
            ),
          ),
          if (_error != null) ...[const SizedBox(height: Insets.sm), Notice(message: describeError(_error!, l10n))],
          const SizedBox(height: Insets.lg),
          PrimaryButton(label: l10n.save, loading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
