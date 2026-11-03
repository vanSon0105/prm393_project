class RegisterModel {
  final RegisterData data;

  RegisterModel({required this.data});

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      data: RegisterData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}

class RegisterData {
  final String message;
  final int profileId;
  final String role;
  final String userName;

  RegisterData({
    required this.message,
    required this.profileId,
    required this.role,
    required this.userName,
  });

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    return RegisterData(
      message: json['message'] as String? ?? '',
      profileId: json['profile_id'] as int? ?? 0,
      // Chú ý chuẩn đặt tên snake_case từ server Go
      role: json['role'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'profile_id': profileId,
      'role': role,
      'user_name': userName,
    };
  }
}
