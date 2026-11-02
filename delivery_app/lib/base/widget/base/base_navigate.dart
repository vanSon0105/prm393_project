import 'dart:io';

import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_router.dart';
import '../dialog/dialog.dart';

abstract class Navigate {
  GlobalKey<NavigatorState> get key;

  BuildContext get currentContext => key.currentContext!;

  bool get canPop => currentContext.canPop();

  Future<T?> add<T>({required AppRoute route, dynamic argument}) async {
    return currentContext.push<T>(route.rawValue, extra: argument);
  }

  Future<void> replace({required AppRoute route, dynamic argument}) async {
    return currentContext.pushReplacement(route.rawValue, extra: argument);
  }

  Future<void> replaceAndClearBackStack({
    required AppRoute route,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    dynamic argument,
  }) async {
    return currentContext.goNamed(
      route.rawValue,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: argument,
    );
  }

  void back<T>({T? result}) {
    debugPrint("----- canPop ? $canPop");
    if (canPop) {
      return currentContext.pop(result);
    } else {
      debugPrint('----- System navigatior pop');
      exit(0);
    }
  }

  void backToRoute({required AppRoute route}) {
    return key.currentState!.popUntil(ModalRoute.withName(route.rawValue));
  }

  void showAppDialog({
    String? title,
    String message = '',
    String? positiveText,
    String? negativeText,
    Function()? onPositiveClicked,
    Function()? onNegativeClicked,
  }) {
    showDialog(
      context: currentContext,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title ?? LocaleKeys.warning_title.tr(),
          message: message,
          positive: positiveText ?? LocaleKeys.btn_OK.tr(),
          negative: negativeText ?? LocaleKeys.btn_cancel.tr(),
          onNegative: onNegativeClicked,
          onPositive: onPositiveClicked,
        );
      },
    );
  }
}
