import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

abstract class Loading {
  Future<void> show() async {
    await EasyLoading.show(maskType: EasyLoadingMaskType.custom);
  }

  Future<void> dismiss() async {
    await EasyLoading.dismiss();
  }

  bool get isShow => EasyLoading.isShow;

  void configLoading() async {
    EasyLoading.instance
      ..indicatorWidget = contentLoading
      ..indicatorColor = Colors.red
      ..maskColor = Colors.black.withAlpha(100)
      ..maskType = EasyLoadingMaskType.custom
      ..dismissOnTap = false
      ..animationStyle = EasyLoadingAnimationStyle.opacity
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = Colors.transparent
      ..boxShadow = []
      ..textColor = Colors.white;
  }

  Widget get contentLoading;
}
