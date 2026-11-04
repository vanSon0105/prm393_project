import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

enum DriverDocumentType {
  cccdFront,
  cccdBack,
  drivingLicenseFront,
  drivingLicenseBack;

  String get label => switch (this) {
    cccdFront => LocaleKeys.register_identity_front.tr(),
    cccdBack => LocaleKeys.register_identity_back.tr(),
    drivingLicenseFront => LocaleKeys.register_license_front.tr(),
    drivingLicenseBack => LocaleKeys.register_license_back.tr(),
  };
}

class DriverDocumentsField
    extends FormField<Map<DriverDocumentType, PlatformFile>> {
  DriverDocumentsField({super.key})
    : super(
        initialValue: const {},
        validator: (documents) {
          if (DriverDocumentType.values.every(
            (type) => documents?.containsKey(type) ?? false,
          )) {
            return null;
          }
          return LocaleKeys.register_documents_required.tr();
        },
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.register_documents_label.tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              LocaleKeys.register_documents_help.tr(),
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final type in DriverDocumentType.values) ...[
              _DocumentTile(
                label: type.label,
                fileName: field.value?[type]?.name,
                uri: field.value?[type]?.uri,
                onSelect: () => _selectFile(field, type),
                onRemove: field.value?.containsKey(type) ?? false
                    ? () {
                        final updated = {...?field.value}..remove(type);
                        field.didChange(updated);
                      }
                    : null,
              ),
              const SizedBox(height: 10),
            ],
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
          ],
        ),
      );

  static Future<void> _selectFile(
    FormFieldState<Map<DriverDocumentType, PlatformFile>> field,
    DriverDocumentType type,
  ) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
      );
      if (!field.mounted || file == null) return;

      final size = await file.length();
      if (!field.mounted) return;
      if (size == 0 || size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(field.context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.register_file_size_error.tr())),
        );
        return;
      }

      field.didChange({...?field.value, type: file});
    } catch (_) {
      if (!field.mounted) return;
      ScaffoldMessenger.of(field.context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.register_file_read_error.tr())),
      );
    }
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.label,
    required this.fileName,
    this.uri,
    required this.onSelect,
    required this.onRemove,
  });

  final String label;
  final Uri? uri;
  final String? fileName;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                size: 24,
                fileName == null
                    ? Icons.upload_file_rounded
                    : Icons.check_circle,
                color: fileName == null ? AppColors.muted : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (fileName != null)
                      Text(
                        fileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSelect,
                child: Text(
                  fileName == null
                      ? LocaleKeys.register_choose_file.tr()
                      : LocaleKeys.register_change_file.tr(),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: LocaleKeys.register_remove_file.tr(
                    namedArgs: {'name': label},
                  ),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          if (uri != null && !kIsWeb)
            Container(
              margin: EdgeInsets.only(left: 36),
              child: Image.file(File.fromUri(uri!), height: 150),
            ),
        ],
      ),
    );
  }
}
