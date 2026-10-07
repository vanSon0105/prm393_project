import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../base/widget/loading/loading.dart';
import '../gen/assets.gen.dart';

class AppLoading extends Loading {
  static final AppLoading instance = AppLoading._internal();

  AppLoading._internal();

  factory AppLoading() {
    return instance;
  }

  @override
  Widget get contentLoading => Container(
    padding: EdgeInsets.all(25),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      color: Colors.white,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Assets.images.loading.image(width: 80, height: 80),
        const SizedBox(height: 10),
        Text(LocaleKeys.loading_txt.tr()),
      ],
    ),
  );
}
