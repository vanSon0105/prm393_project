import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/domain/entities/login_status.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/login/login_state.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_provider.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

Duration? disableRetry(int retryCount, Object error) => null;

@Riverpod(retry: disableRetry)
class LoginViewModel extends _$LoginViewModel {
  @override
  LoginState build() {
    return LoginState();
  }

  Future<void> login({
    required String userName,
    required String password,
  }) async {
    try {
      AppLoading.instance.show();
      final api = ref.read(authenticationRepositoryProvider);
      final response = await api.login(
        param: LoginParam(userName: userName, password: password),
      );
      final roleValue = response.data?.role?.trim().toUpperCase();
      Role? role;
      for (final candidate in Role.values) {
        if (candidate.value == roleValue) {
          role = candidate;
          break;
        }
      }
      if (role == null) {
        AppNavigate.instance.showAppDialog(
          message: LocaleKeys.login_unknown_role.tr(),
        );
        return;
      }
      final status = LoginStatus.valueOf(response.data?.status ?? '');
      switch (status) {
        case LoginStatus.approved:
          ref
              .read(appViewModelProvider.notifier)
              .updateAppData(role, profileId: response.data?.profileId);
          AppNavigate.instance.gotoScreenBy(screen: role.screen);
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
