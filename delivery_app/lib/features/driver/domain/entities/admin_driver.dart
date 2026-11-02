class AdminDriver {
  const AdminDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.avatarUrl,
  });

  final int id;
  final String name;
  final String phone;
  final String address;
  final String avatarUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
        .toUpperCase();
  }
}
