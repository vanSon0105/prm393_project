import 'dart:typed_data';

import 'role.dart';

class RegisterDocument {
  const RegisterDocument({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class RegisterAccountRequest {
  const RegisterAccountRequest({
    required this.fullName,
    required this.userName,
    required this.password,
    required this.phoneNumber,
    required this.role,
    this.vehicleId,
    this.licensePlate,
    this.documents = const {},
  });

  final String fullName;
  final String userName;
  final String password;
  final String phoneNumber;
  final Role role;
  final int? vehicleId;
  final String? licensePlate;
  final Map<String, RegisterDocument> documents;
}

class RegisterAccountResult {
  const RegisterAccountResult({
    required this.profileId,
    required this.userName,
    required this.role,
  });

  final int profileId;
  final String userName;
  final Role role;

  factory RegisterAccountResult.fromJson(Map<String, dynamic> json) {
    final profileId = json['profile_id'];
    final userName = json['user_name'];
    final role = json['role'];
    if (profileId is! int || userName is! String || role is! String) {
      throw const FormatException('Invalid registration response');
    }
    return RegisterAccountResult(
      profileId: profileId,
      userName: userName,
      role: Role.values.firstWhere(
        (value) => value.value == role,
        orElse: () => throw const FormatException('Invalid registration role'),
      ),
    );
  }
}
