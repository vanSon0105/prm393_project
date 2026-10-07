import 'package:delivery_app/features/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gen/assets.gen.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.watch(splashViewModelProvider);
        return Center(
          child: Assets.images.delivery.image(width: 200, height: 200),
        );
      },
    );
  }
}
