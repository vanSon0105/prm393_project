import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../../driver/domain/entities/admin_driver.dart';
import '../../../driver/presentation/providers/driver_provider.dart';
import '../../domain/entities/app_user.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/user_details_sheet.dart';
import '../widgets/user_role_filter.dart';
import '../widgets/user_search_field.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);
    final driverState = ref.watch(adminDriversProvider);
    final driverUsers = [
      for (final driver in driverState.asData?.value ?? <AdminDriver>[])
        AppUser(
          name: driver.name,
          email: '',
          phone: driver.phone,
          role: 'Tài xế',
          isActive: true,
          driverId: driver.id,
        ),
    ];
    final users = state
        .copyWith(users: [...state.users, ...driverUsers])
        .filteredUsers;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: AppScreenHeader(
            eyebrow: LocaleKeys.users_admin.tr(),
            title: LocaleKeys.users_management.tr(),
            actionIcon: Icons.more_horiz,
            onActionPressed: () =>
                _showMessage(context, LocaleKeys.users_admin_options_demo.tr()),
          ),
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: UserSearchField(onChanged: notifier.updateSearch),
        ),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: UserRoleFilter(
              selectedRole: state.selectedRole,
              onRoleChanged: notifier.selectRole,
            ),
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              LocaleKeys.users_count.tr(
                namedArgs: {'count': '${users.length}'},
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SizedBox(height: 12),
        if (driverState.isLoading) const LinearProgressIndicator(),
        if (driverState.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(child: Text('Không tải được tài xế từ API.')),
                TextButton(
                  onPressed: () => ref.invalidate(adminDriversProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: users.isEmpty ? 1 : users.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (users.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      LocaleKeys.users_none.tr(),
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

  Future<void> _showUserActions(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final showDetails = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  InitialsAvatar(label: user.initials, size: 52),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        SizedBox(height: 4),
                        Text(
                          user.email.isNotEmpty ? user.email : user.phone,
                          style: TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              Divider(height: 1),
              SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _actionIcon(Assets.images.icUser),
                title: Text(LocaleKeys.users_view_info.tr()),
                trailing: Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext, true);
                },
              ),
              if (user.driverId == null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _actionIcon(
                    user.isActive
                        ? Assets.images.icUserLock
                        : Assets.images.icUserCheck,
                    danger: user.isActive,
                  ),
                  title: Text(
                    user.isActive
                        ? LocaleKeys.users_lock_account.tr()
                        : LocaleKeys.users_unlock_account.tr(),
                    style: TextStyle(
                      color: user.isActive
                          ? AppColors.danger
                          : AppColors.success,
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
                      user.isActive
                          ? LocaleKeys.users_account_locked_notice.tr(
                              namedArgs: {'name': user.name},
                            )
                          : LocaleKeys.users_account_unlocked_notice.tr(
                              namedArgs: {'name': user.name},
                            ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (showDetails != true || !context.mounted) return;
    AdminDriver? driver;
    for (final candidate
        in ref.read(adminDriversProvider).asData?.value ?? <AdminDriver>[]) {
      if (candidate.id == user.driverId) {
        driver = candidate;
        break;
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UserDetailsSheet(user: user, driver: driver),
    );
  }

  Widget _actionIcon(SvgGenImage icon, {bool danger = false}) {
    return Container(
      padding: EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerSoft : AppColors.blueSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: icon.svg(
        width: 21,
        height: 21,
        colorFilter: ColorFilter.mode(
          danger ? AppColors.danger : AppColors.blue,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
