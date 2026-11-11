class AppUserDocuments {
  const AppUserDocuments({
    required this.licenseFrontUrl,
    required this.licenseBackUrl,
    required this.identityFrontUrl,
    required this.identityBackUrl,
  });

  final String licenseFrontUrl;
  final String licenseBackUrl;
  final String identityFrontUrl;
  final String identityBackUrl;

  factory AppUserDocuments.fromJson(Map<String, dynamic> json) =>
      AppUserDocuments(
        licenseFrontUrl: json['driving_license_front_url'] as String? ?? '',
        licenseBackUrl: json['driving_license_back_url'] as String? ?? '',
        identityFrontUrl: json['identity_card_front_url'] as String? ?? '',
        identityBackUrl: json['identity_card_back_url'] as String? ?? '',
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.address,
    required this.role,
    this.documents,
  });

  final int id;
  final String name;
  final String username;
  final String phone;
  final String address;
  final String role;
  final AppUserDocuments? documents;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['profile_id'] as num).toInt(),
    name: json['full_name'] as String? ?? '',
    username: json['user_name'] as String? ?? '',
    phone: json['phone_number'] as String? ?? '',
    address: json['address'] as String? ?? '',
    role: json['role'] as String? ?? '',
    documents: json['driver_documents'] is Map
        ? AppUserDocuments.fromJson(
            Map<String, dynamic>.from(json['driver_documents'] as Map),
          )
        : null,
  );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
        .toUpperCase();
  }
}
