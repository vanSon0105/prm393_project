import 'dart:async';

import 'package:delivery_app/data/local/sharepreference/share_preference_repository.dart';
import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_viewmodel.g.dart';

@riverpod
class SplashViewModel extends _$SplashViewModel {
  @override
  void build() {
    debugPrint('--------- init splash viewmodel');
    unawaited(navigateTest());
  }

  Future<void> navigateTest() async {
    await Future.delayed(const Duration(seconds: 5));
    final prefers = ref.read(appSharePreferencesProvider);
    final dataSaved = prefers.data;
    if (dataSaved != null) {
      AppNavigate.instance.gotoScreenBy(screen: dataSaved.role.screen);
      ref
          .read(appViewModelProvider.notifier)
          .updateAppData(dataSaved.role, profileId: dataSaved.profileId);
    } else {
      AppNavigate.instance.gotoLogin();
    }
  }
}
