class LoginModel {
  final LoginData? data;

  LoginModel({this.data});

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      data: json['data'] != null
          ? LoginData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data?.toJson()};
  }
}

class LoginData {
  final int? profileId;
  final String? userName;
  final String? role;
  final String? status;
  final String? message;

  LoginData({
    this.profileId,
    this.userName,
    this.role,
    this.status,
    this.message,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      profileId: json['profile_id'] as int?,
      userName: json['user_name'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'user_name': userName,
      'role': role,
      'status': status,
      'message': message,
    };
  }
}
