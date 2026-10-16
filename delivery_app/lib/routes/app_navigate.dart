import 'package:flutter/material.dart';

import '../base/widget/base/base_navigate.dart';
import 'app_router.dart';

class AppNavigate extends Navigate {
  static final applicationKey = GlobalKey<NavigatorState>();
  static final AppNavigate instance = AppNavigate._internal();

  @override
  GlobalKey<NavigatorState> get key => applicationKey;

  factory AppNavigate() {
    return instance;
  }

  AppNavigate._internal();

  Future<dynamic> gotoLogin() async {
    return replaceAndClearBackStack(route: AppRoute.login);
  }

  Future<void> gotoAdmin() async {
    return replaceAndClearBackStack(route: AppRoute.admin);
  }

  Future<void> gotoMap() async {
    return replaceAndClearBackStack(route: AppRoute.map);
  }

  Future<void> gotoDetailDelivery() async {
    return replaceAndClearBackStack(route: AppRoute.detailDelivery);
  }

  Future<void> gotoSetting() async {
    return replaceAndClearBackStack(route: AppRoute.setting);
  }
}
