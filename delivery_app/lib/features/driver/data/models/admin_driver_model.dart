import '../../domain/entities/admin_driver.dart';

class AdminDriverModel extends AdminDriver {
  const AdminDriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.address,
    required super.avatarUrl,
    super.documents,
  });

  factory AdminDriverModel.fromJson(Map<String, dynamic> json) {
    final id = json['driver_id'];
    if (id is! int) {
      throw const FormatException('Driver ID is missing or invalid');
    }

    final name = (json['full_name'] as String?)?.trim() ?? '';
    final avatar = (json['avatar_url'] as String?)?.trim() ?? '';
    String imageUrl(String key) {
      final value = (json[key] as String?)?.trim() ?? '';
      return value.endsWith('/image/') ? '' : value;
    }

    return AdminDriverModel(
      id: id,
      name: name.isEmpty ? 'Tài xế #$id' : name,
      phone: (json['phone_number'] as String?)?.trim() ?? '',
      address: (json['address'] as String?)?.trim() ?? '',
      avatarUrl: avatar.endsWith('/image/') ? '' : avatar,
      documents: DriverDocuments(
        licenseFrontUrl: imageUrl('driving_license_front_url'),
        licenseBackUrl: imageUrl('driving_license_back_url'),
        identityFrontUrl: imageUrl('identity_card_front_url'),
        identityBackUrl: imageUrl('identity_card_back_url'),
      ),
    );
  }
}
