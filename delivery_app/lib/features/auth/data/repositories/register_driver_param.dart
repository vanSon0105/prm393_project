import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:dio/dio.dart';

class RegisterDriverParam extends ApiParam {
  final String userName;
  final String password;
  final String phoneNumber;
  final int vehicleId;
  final String licensePlate;
  final String drivingLicenseFrontSide;
  final String drivingLicenseBackSide;
  final String frontSideOfTheIdentityCard;
  final String backSideOfTheIdentityCard;

  RegisterDriverParam({
    required this.userName,
    required this.password,
    required this.phoneNumber,
    required this.vehicleId,
    required this.licensePlate,
    required this.drivingLicenseFrontSide,
    required this.drivingLicenseBackSide,
    required this.frontSideOfTheIdentityCard,
    required this.backSideOfTheIdentityCard,
  });

  @override
  String get method => Method.post;

  @override
  String get path => '/api/user/register';

  @override
  bool get useMultipart => true;

  @override
  Future<FormData> get formData async {
    return FormData.fromMap({
      'user_name': userName,
      'password': password,
      'phone_number': phoneNumber,
      'role': Role.driver.value,
      'vehicle_id': vehicleId,
      'license_plate': licensePlate,
      'driving_license_front_side': await MultipartFile.fromFile(
        drivingLicenseFrontSide,
        filename: 'driving_license_front_side.jpg',
      ),
      'driving_license_back_side': await MultipartFile.fromFile(
        drivingLicenseBackSide,
        filename: 'driving_license_back_side.jpg',
      ),
      'front_side_of_the_identity_card': await MultipartFile.fromFile(
        frontSideOfTheIdentityCard,
        filename: 'front_side_of_the_identity_card.jpg',
      ),
      'the_back_of_the_identity_card': await MultipartFile.fromFile(
        backSideOfTheIdentityCard,
        filename: 'the_back_of_the_identity_card.jpg',
      ),
    });
  }
}
