import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/app_user.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/user_role_filter.dart';
import '../widgets/user_search_field.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);
    final users = state.filteredUsers;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: AppScreenHeader(
            eyebrow: 'Quản trị',
            title: 'Quản lý người dùng',
            actionIcon: Icons.more_horiz,
            onActionPressed: () =>
                _showMessage(context, 'Tùy chọn quản trị (demo)'),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: UserSearchField(onChanged: notifier.updateSearch),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: UserRoleFilter(
              selectedRole: state.selectedRole,
              onRoleChanged: notifier.selectRole,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${users.length} người dùng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: users.isEmpty ? 1 : users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'Không tìm thấy người dùng',
                      style: TextStyle(color: AppColors.textSoft),
                    ),
                  ),
                );
              }

              final user = users[index];
              return UserCard(
                user: user,
                onTap: () => _showUserActions(context, ref, user),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUserActions(BuildContext context, WidgetRef ref, AppUser user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  InitialsAvatar(label: user.initials, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _actionIcon(Icons.person_outline),
                title: const Text('Xem thông tin'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessage(context, '${user.name} • ${user.phone}');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _actionIcon(
                  user.isActive ? Icons.lock_outline : Icons.lock_open_outlined,
                  danger: user.isActive,
                ),
                title: Text(
                  user.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                  style: TextStyle(
                    color: user.isActive ? AppColors.danger : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref
                      .read(adminUsersProvider.notifier)
                      .toggleStatus(user.email);
                  _showMessage(
                    context,
                    '${user.isActive ? 'Đã khóa' : 'Đã mở khóa'} '
                    'tài khoản ${user.name}',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFBEAEC) : AppColors.blueSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 21,
        color: danger ? AppColors.danger : AppColors.blue,
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
