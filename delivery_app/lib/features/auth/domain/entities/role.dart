import 'package:delivery_app/gen/assets.gen.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:delivery_app/routes/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

enum Role {
  admin(value: 'ADMIN'),
  driver(value: 'DRIVER'),
  customer(value: 'CUSTOMER');

  final String value;

  const Role({required this.value});
}

extension RoleEx on Role {
  Widget getIcon({ColorFilter? colorFilter}) {
    switch (this) {
      case Role.admin:
        return Assets.images.icAdmin.svg(colorFilter: colorFilter);
      case Role.driver:
        return Assets.images.icDriver.svg(colorFilter: colorFilter);
      case Role.customer:
        return Assets.images.icUser.svg(colorFilter: colorFilter);
    }
  }

  String get title {
    switch (this) {
      case Role.admin:
        return LocaleKeys.login_admin_txt.tr();
      case Role.driver:
        return LocaleKeys.login_driver_txt.tr();
      case Role.customer:
        return LocaleKeys.login_customer_txt.tr();
    }
  }

  AppRoute get screen {
    switch (this) {
      case Role.admin:
        return AppRoute.admin;
      case Role.driver:
        return AppRoute.map;
      case Role.customer:
        return AppRoute.map;
    }
  }
}
