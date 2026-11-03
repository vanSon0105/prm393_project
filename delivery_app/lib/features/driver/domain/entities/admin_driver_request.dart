import 'admin_driver.dart';

class AdminDriverRequest extends AdminDriver {
  const AdminDriverRequest({
    required super.id,
    required super.name,
    required super.phone,
    required super.address,
    required super.avatarUrl,
    required this.licenseFrontUrl,
    required this.licenseBackUrl,
    required this.identityFrontUrl,
    required this.identityBackUrl,
  });

  final String licenseFrontUrl;
  final String licenseBackUrl;
  final String identityFrontUrl;
  final String identityBackUrl;
}
