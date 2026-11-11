import 'package:delivery_app/data/network/base/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_users_repository.dart';
import '../../domain/entities/app_user.dart';

class AdminUsersState {
  const AdminUsersState({this.searchQuery = '', this.selectedRole = 'ALL'});

  final String searchQuery;
  final String selectedRole;

  List<AppUser> filter(List<AppUser> users) {
    final query = searchQuery.trim().toLowerCase();
    return users
        .where((user) {
          final matchesRole =
              selectedRole == 'ALL' || user.role == selectedRole;
          final matchesSearch =
              query.isEmpty ||
              user.name.toLowerCase().contains(query) ||
              user.username.toLowerCase().contains(query) ||
              user.phone.toLowerCase().contains(query);
          return matchesRole && matchesSearch;
        })
        .toList(growable: false);
  }

  AdminUsersState copyWith({String? searchQuery, String? selectedRole}) =>
      AdminUsersState(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedRole: selectedRole ?? this.selectedRole,
      );
}

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  @override
  AdminUsersState build() => const AdminUsersState();

  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void selectRole(String role) {
    state = state.copyWith(selectedRole: role);
  }
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersState>(
      AdminUsersNotifier.new,
    );

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepository(ref.watch(apiProviderProvider)),
);

final adminUsersListProvider = FutureProvider<List<AppUser>>(
  (ref) => ref.watch(adminUsersRepositoryProvider).getUsers(),
  retry: (retryCount, error) => null,
);
