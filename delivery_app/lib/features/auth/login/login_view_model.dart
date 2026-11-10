import 'package:delivery_app/data/local/sharepreference/model/data_saved.dart';
import 'package:delivery_app/data/local/sharepreference/share_preference_repository.dart';
import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/domain/entities/login_status.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/login/login_state.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_provider.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

Duration? disableRetry(int retryCount, Object error) => null;

@Riverpod(retry: disableRetry)
class LoginViewModel extends _$LoginViewModel {
  @override
  LoginState build() {
    return LoginState(Role.customer);
  }

  void changeRole(Role role) {
    state = LoginState(role);
  }

  Future<void> login({
    required String userName,
    required String password,
    required Role role,
  }) async {
    debugPrint('------- Login role: $role');
    try {
      AppLoading.instance.show();
      final api = ref.read(authenticationRepositoryProvider);
      final response = await api.login(
        param: LoginParam(userName: userName, password: password, role: role),
      );
      final status = LoginStatus.valueOf(response.data?.status ?? '');
      final prefers = ref.read(appSharePreferencesProvider);
      await prefers.saveData(
        DataSaved(role: role, profileId: response.data?.profileId ?? -1),
      );
      switch (status) {
        case LoginStatus.approved:
          AppNavigate.instance.gotoScreenBy(screen: role.screen);
          ref
              .read(appViewModelProvider.notifier)
              .updateAppData(role, profileId: response.data?.profileId);
        case LoginStatus.pending:
          AppNavigate.instance.showAppDialog(
            message: response.data?.message ?? '',
          );
        case LoginStatus.reject:
          final driverId = response.data?.profileId;
          if (role == Role.driver && driverId != null && driverId > 0) {
            ref.invalidate(rejectedDriverRequestProvider(driverId));
            AppNavigate.instance.gotoDriverResubmit(driverId);
          } else {
            AppNavigate.instance.showAppDialog(
              message: response.data?.message ?? '',
            );
          }
      }
    } catch (_) {
    } finally {
      AppLoading.instance.dismiss();
    }
  }
}
