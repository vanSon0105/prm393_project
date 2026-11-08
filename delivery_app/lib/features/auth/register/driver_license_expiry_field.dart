import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DriverLicenseExpiryField extends StatefulWidget {
  const DriverLicenseExpiryField({required this.controller, super.key});

  final TextEditingController controller;

  static String? validate(String? value) {
    final text = (value ?? '').trim();
    final date = DateTime.tryParse(text);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
        date == null ||
        _format(date) != text) {
      return LocaleKeys.register_license_expiry_error.tr();
    }
    if (date.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return LocaleKeys.register_license_expiry_past.tr();
    }
    return null;
  }

  static String _format(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  State<DriverLicenseExpiryField> createState() =>
      _DriverLicenseExpiryFieldState();
}

class _DriverLicenseExpiryFieldState extends State<DriverLicenseExpiryField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(covariant DriverLicenseExpiryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncFromController();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    super.dispose();
  }

  void _syncFromController() {
    final field = _fieldKey.currentState;
    if (field != null && field.value != widget.controller.text) {
      field.didChange(widget.controller.text);
    }
  }

  Future<void> _selectDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final saved = DateTime.tryParse(widget.controller.text);
    final initial = saved != null && !saved.isBefore(today)
        ? saved
        : today.add(const Duration(days: 365));
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(today.year + 50, 12, 31),
    );
    if (mounted && selected != null) {
      widget.controller.text = DriverLicenseExpiryField._format(selected);
    }
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    key: _fieldKey,
    initialValue: widget.controller.text,
    validator: DriverLicenseExpiryField.validate,
    builder: (field) {
      final value = field.value ?? '';
      return Semantics(
        button: true,
        label: LocaleKeys.register_license_expiry.tr(),
        child: InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            isEmpty: value.isEmpty,
            decoration: InputDecoration(
              labelText: LocaleKeys.register_license_expiry.tr(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              value.isEmpty
                  ? LocaleKeys.register_license_expiry_hint.tr()
                  : value,
              style: value.isEmpty
                  ? TextStyle(color: Theme.of(context).hintColor)
                  : null,
            ),
          ),
        ),
      );
    },
  );
}
