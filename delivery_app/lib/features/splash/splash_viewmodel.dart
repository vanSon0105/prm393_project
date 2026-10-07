import 'dart:async';

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
    AppNavigate.instance.gotoLogin();
  }
}
