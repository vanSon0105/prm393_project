import 'package:delivery_app/data/network/api_posts_sample/post_response.dart';
import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/widget/app_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_view_model.g.dart';

@riverpod
class LoginViewModel extends _$LoginViewModel {
  @override
  Future<PostResponse> build() async {
    debugPrint('--------- init login viewmodel');
    AppLoading.instance.show();
    final api = ref.read(apiRepositoryProvider);
    await Future.delayed(const Duration(seconds: 5));
    final data = await api.getPostResponse();
    AppLoading.instance.dismiss();
    return data;
  }
}
