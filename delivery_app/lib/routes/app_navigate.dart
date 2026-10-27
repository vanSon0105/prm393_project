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

  Future<dynamic> gotoRegister() async {
    return add(route: AppRoute.register);
  }

  Future<void> gotoAdmin() async {
    return replaceAndClearBackStack(route: AppRoute.admin);
  }

  Future<void> gotoDriverEarnings() async {
    await add<void>(route: AppRoute.driverEarnings);
  }

  Future<void> gotoDriverRating() async {
    await add<void>(route: AppRoute.driverRating);
  }

  Future<void> gotoTripPayment() async {
    await add<void>(route: AppRoute.tripPayment);
  }

  Future<void> gotoEditProfile() async {
    await add<void>(route: AppRoute.editProfile);
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
