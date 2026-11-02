import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

enum DriverDocumentType {
  cccdFront('Mặt trước CCCD'),
  cccdBack('Mặt sau CCCD'),
  drivingLicense('Giấy phép lái xe'),
  vehicleInsurance('Bảo hiểm xe');

  const DriverDocumentType(this.label);

  final String label;
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
          return 'Vui lòng chọn đủ ảnh/tệp cho 4 mục giấy tờ.';
        },
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ảnh giấy tờ *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn ảnh JPG, PNG hoặc tệp PDF; mỗi tệp tối đa 10 MB.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final type in DriverDocumentType.values) ...[
              _DocumentTile(
                label: type.label,
                fileName: field.value?[type]?.name,
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
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (!field.mounted || file == null) return;

      final size = await file.length();
      if (!field.mounted) return;
      if (size == 0 || size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(field.context).showSnackBar(
          const SnackBar(
            content: Text('Tệp cần có dung lượng từ 1 byte đến 10 MB.'),
          ),
        );
        return;
      }

      field.didChange({...?field.value, type: file});
    } catch (_) {
      if (!field.mounted) return;
      ScaffoldMessenger.of(field.context).showSnackBar(
        const SnackBar(content: Text('Không thể mở tệp. Vui lòng thử lại.')),
      );
    }
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.label,
    required this.fileName,
    required this.onSelect,
    required this.onRemove,
  });

  final String label;
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
      child: Row(
        children: [
          Icon(
            fileName == null ? Icons.upload_file_rounded : Icons.check_circle,
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
            child: Text(fileName == null ? 'Chọn tệp' : 'Đổi'),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Bỏ tệp $label',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}
