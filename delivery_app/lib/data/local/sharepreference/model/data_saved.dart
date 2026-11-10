import 'dart:convert';

import 'package:delivery_app/features/auth/domain/entities/role.dart';

class DataSaved {
  final Role role;
  final int profileId;

  DataSaved({required this.role, required this.profileId});

  factory DataSaved.fromJson(String json) {
    final map = jsonDecode(json);
    return DataSaved(
      role: Role.valueOf(map['role']),
      profileId: map['profileId'],
    );
  }

  Map<String, dynamic> get toJson {
    return {'role': role.value, 'profileId': profileId};
  }
}
