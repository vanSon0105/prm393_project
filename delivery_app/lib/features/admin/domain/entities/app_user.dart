class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  AppUser copyWith({bool? isActive}) {
    return AppUser(
      name: name,
      email: email,
      phone: phone,
      role: role,
      isActive: isActive ?? this.isActive,
    );
  }
}
