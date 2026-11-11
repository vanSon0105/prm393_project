import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/user_details_sheet.dart';
import '../widgets/user_role_filter.dart';
import '../widgets/user_search_field.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);
    final usersValue = ref.watch(adminUsersListProvider);
    final users = filter.filter(usersValue.asData?.value ?? const []);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: AppScreenHeader(
            eyebrow: LocaleKeys.users_admin.tr(),
            title: LocaleKeys.users_management.tr(),
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
              selectedRole: filter.selectedRole,
              onRoleChanged: notifier.selectRole,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (usersValue.hasValue)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    LocaleKeys.users_count.tr(
                      namedArgs: {'count': '${users.length}'},
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: LocaleKeys.admin_refresh.tr(),
                  onPressed: () => ref.invalidate(adminUsersListProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: usersValue.when(
            skipLoadingOnRefresh: false,
            data: (_) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: users.isEmpty ? 1 : users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        LocaleKeys.users_none.tr(),
                        style: const TextStyle(color: AppColors.textSoft),
                      ),
                    ),
                  );
                }
                final user = users[index];
                return UserCard(
                  user: user,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    backgroundColor: AppColors.surfaceStrong,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => UserDetailsSheet(user: user),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LocaleKeys.admin_users_load_error.tr()),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(adminUsersListProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(LocaleKeys.admin_try_again.tr()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
