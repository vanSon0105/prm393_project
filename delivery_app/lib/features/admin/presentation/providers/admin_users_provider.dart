import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';

class AdminUsersState {
  const AdminUsersState({
    required this.users,
    this.searchQuery = '',
    this.selectedRole = 'Tất cả',
  });

  final List<AppUser> users;
  final String searchQuery;
  final String selectedRole;

  List<AppUser> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();
    return users
        .where((user) {
          final matchesRole =
              selectedRole == 'Tất cả' || user.role == selectedRole;
          final matchesSearch =
              query.isEmpty ||
              user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.phone.toLowerCase().contains(query);
          return matchesRole && matchesSearch;
        })
        .toList(growable: false);
  }

  AdminUsersState copyWith({
    List<AppUser>? users,
    String? searchQuery,
    String? selectedRole,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  @override
  AdminUsersState build() {
    return const AdminUsersState(
      users: [
        AppUser(
          name: 'Trần Anh',
          email: 'trananh@gmail.com',
          phone: '0912345678',
          role: 'Khách hàng',
          isActive: true,
        ),
        AppUser(
          name: 'Nguyễn Bình',
          email: 'nguyenbinh@gmail.com',
          phone: '0987654321',
          role: 'Tài xế',
          isActive: true,
        ),
        AppUser(
          name: 'Lê Hoàng',
          email: 'lehoang@gmail.com',
          phone: '0905123456',
          role: 'Tài xế',
          isActive: false,
        ),
        AppUser(
          name: 'Phạm Mai',
          email: 'phammai@gmail.com',
          phone: '0933111222',
          role: 'Khách hàng',
          isActive: true,
        ),
        AppUser(
          name: 'Đỗ Minh',
          email: 'domin@gmail.com',
          phone: '0966999888',
          role: 'Admin',
          isActive: true,
        ),
        AppUser(
          name: 'Nguyễn Lan',
          email: 'nguyenlan@gmail.com',
          phone: '0977555444',
          role: 'Khách hàng',
          isActive: false,
        ),
      ],
    );
  }

  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void selectRole(String role) {
    state = state.copyWith(selectedRole: role);
  }

  void toggleStatus(String email) {
    state = state.copyWith(
      users: [
        for (final user in state.users)
          if (user.email == email)
            user.copyWith(isActive: !user.isActive)
          else
            user,
      ],
    );
  }
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersState>(
      AdminUsersNotifier.new,
    );
