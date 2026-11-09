import 'dart:typed_data';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/param.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:dio/dio.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.imageUrl,
  });

  final int id;
  final String userName;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String imageUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final image = json['image']?.toString() ?? '';
    final imageUri = Uri.tryParse(image);
    return UserProfile(
      id: (json['profile_id'] as num).toInt(),
      userName: json['user_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      imageUrl:
          image.isEmpty || imageUri == null || imageUri.pathSegments.isEmpty
          ? ''
          : Uri.parse(Environment.baseUrl)
                .resolve(
                  '/image/${Uri.encodeComponent(imageUri.pathSegments.last)}',
                )
                .toString(),
    );
  }
}

class ProfileChanges {
  const ProfileChanges({
    this.fullName,
    this.phoneNumber,
    this.address,
    this.imageBytes,
    this.imageName,
  });

  final String? fullName;
  final String? phoneNumber;
  final String? address;
  final Uint8List? imageBytes;
  final String? imageName;

  bool get isEmpty =>
      fullName == null &&
      phoneNumber == null &&
      address == null &&
      imageBytes == null;
}

class ProfileRepository {
  const ProfileRepository(this._api);

  final ApiProvider _api;

  Future<UserProfile> getProfile(int id) async {
    final response = await _api.requestApi(param: _ProfileParam(id));
    return _parse(response);
  }

  Future<UserProfile> updateProfile(int id, ProfileChanges changes) async {
    final response = await _api.requestApi(
      param: _ProfileParam(id, changes: changes),
    );
    return _parse(response);
  }

  UserProfile _parse(dynamic response) {
    if (response is! Map || response['data'] is! Map) {
      throw const FormatException('Invalid profile response');
    }
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

class _ProfileParam extends ApiParam {
  _ProfileParam(this.id, {this.changes});

  final int id;
  final ProfileChanges? changes;

  @override
  String get path => '/api/$id/profile';

  @override
  String get method => changes == null ? Method.get : Method.post;

  @override
  String get contentType => changes == null
      ? HeaderContentType.applicationJson
      : HeaderContentType.multipartFormData;

  @override
  bool get useMultipart => changes != null;

  @override
  Future<FormData> get formData async => FormData.fromMap({
    if (changes!.fullName != null) 'full_name': changes!.fullName,
    if (changes!.phoneNumber != null) 'phone_number': changes!.phoneNumber,
    if (changes!.address != null) 'address': changes!.address,
    if (changes!.imageBytes != null)
      'image': MultipartFile.fromBytes(
        changes!.imageBytes!,
        filename: changes!.imageName,
      ),
  });
}
