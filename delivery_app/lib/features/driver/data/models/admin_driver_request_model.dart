import '../../domain/entities/admin_driver_request.dart';
import 'admin_driver_model.dart';

class AdminDriverRequestModel extends AdminDriverRequest {
  const AdminDriverRequestModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.address,
    required super.avatarUrl,
    required super.licenseFrontUrl,
    required super.licenseBackUrl,
    required super.identityFrontUrl,
    required super.identityBackUrl,
  });

  factory AdminDriverRequestModel.fromJson(Map<String, dynamic> json) {
    final driver = AdminDriverModel.fromJson(json);
    String imageUrl(String key) {
      final value = (json[key] as String?)?.trim() ?? '';
      return value.endsWith('/image/') ? '' : value;
    }

    return AdminDriverRequestModel(
      id: driver.id,
      name: driver.name,
      phone: driver.phone,
      address: driver.address,
      avatarUrl: driver.avatarUrl,
      licenseFrontUrl: imageUrl('driving_license_front_url'),
      licenseBackUrl: imageUrl('driving_license_back_url'),
      identityFrontUrl: imageUrl('identity_card_front_url'),
      identityBackUrl: imageUrl('identity_card_back_url'),
    );
  }
}
