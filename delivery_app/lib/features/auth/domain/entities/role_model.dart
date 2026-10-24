import 'package:delivery_app/gen/assets.gen.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

enum Role {
  admin(value: 1),
  driver(value: 2),
  customer(value: 3);

  final int value;

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
}
