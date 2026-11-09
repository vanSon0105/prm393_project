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
    this.licensePlateExpiredDate,
    this.documents = const {},
  });

  final String fullName;
  final String userName;
  final String password;
  final String phoneNumber;
  final Role role;
  final int? vehicleId;
  final String? licensePlate;
  final String? licensePlateExpiredDate;
  final Map<String, RegisterDocument> documents;
}
