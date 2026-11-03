import 'package:delivery_app/features/auth/register/register_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/repository_module.dart';
import '../../../widget/app_loading.dart';

part 'register_view_model.g.dart';

Duration? disableRetry(int retryCount, Object error) => null;

@Riverpod(retry: disableRetry)
class RegisterViewModel extends _$RegisterViewModel {
  @override
  RegisterState build(RegisterState state) {
    return state;
  }

  Future<void> getVehicleType() async {
    try {
      AppLoading.instance.show();
      final api = ref.read(authenticationRepositoryProvider);
      final response = await api.getVehicleTypes();
      state.copyWidth(vehicles: response.data);
    } catch (e) {
    } finally {
      AppLoading.instance.dismiss();
    }
  }
}
