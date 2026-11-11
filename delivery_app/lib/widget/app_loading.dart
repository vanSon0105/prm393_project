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
    padding: const EdgeInsets.all(25),
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      color: Colors.white,
    ),
    child: Assets.images.loading.image(width: 80, height: 80),
  );
}
