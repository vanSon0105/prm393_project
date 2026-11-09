import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:dio/dio.dart';

class RegisterDriverParam extends ApiParam {
  final String fullName;
  final String userName;
  final String password;
  final String phoneNumber;
  final int vehicleId;
  final String licensePlate;
  final String licensePlateExpiredDate;
  final double latitude;
  final double longitude;
  final Map<String, RegisterDocument> documents;

  RegisterDriverParam({
    required this.fullName,
    required this.userName,
    required this.password,
    required this.phoneNumber,
    required this.vehicleId,
    required this.licensePlate,
    required this.licensePlateExpiredDate,
    required this.latitude,
    required this.longitude,
    required this.documents,
  });

  @override
  String get method => Method.post;

  @override
  String get path => '/api/user/register';

  @override
  String get contentType => HeaderContentType.multipartFormData;

  @override
  bool get useMultipart => true;

  @override
  Map<String, dynamic> get extra => const {'skipApiErrorDialog': true};

  @override
  Future<FormData> get formData async {
    return FormData.fromMap({
      'full_name': fullName.trim(),
      'user_name': userName.trim(),
      'password': password,
      'phone_number': phoneNumber.replaceAll(' ', ''),
      'role': Role.driver.value,
      'vehicle_id': vehicleId,
      'license_plate': licensePlate.trim(),
      'license_plate_expired_date': licensePlateExpiredDate.trim(),
      'latitude': latitude,
      'longitude': longitude,
      for (final entry in documents.entries)
        entry.key: MultipartFile.fromBytes(
          entry.value.bytes,
          filename: entry.value.name,
        ),
    });
  }
}
