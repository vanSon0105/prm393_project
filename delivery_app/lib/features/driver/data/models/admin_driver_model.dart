import '../../domain/entities/admin_driver.dart';

class AdminDriverModel extends AdminDriver {
  const AdminDriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.address,
    required super.avatarUrl,
  });

  factory AdminDriverModel.fromJson(Map<String, dynamic> json) {
    final id = json['driver_id'];
    if (id is! int) {
      throw const FormatException('Driver ID is missing or invalid');
    }

    final name = (json['full_name'] as String?)?.trim() ?? '';
    final avatar = (json['avatar_url'] as String?)?.trim() ?? '';
    return AdminDriverModel(
      id: id,
      name: name.isEmpty ? 'Tài xế #$id' : name,
      phone: (json['phone_number'] as String?)?.trim() ?? '',
      address: (json['address'] as String?)?.trim() ?? '',
      avatarUrl: avatar.endsWith('/image/') ? '' : avatar,
    );
  }
}
