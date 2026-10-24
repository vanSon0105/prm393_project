import 'package:flutter/material.dart';

import '../../core/theme/trip_colors.dart';
import '../../gen/assets.gen.dart';

class AssetIcon extends StatelessWidget {
  const AssetIcon(this.name, {super.key, this.color = ink, this.size = 22});
  final String name;
  final Color color;
  final double size;
  SvgGenImage get asset => switch (name) {
    'ic_back' => Assets.images.icBack,
    'ic_car' => Assets.images.icCar,
    'ic_close' => Assets.images.icClose,
    'ic_continue' => Assets.images.icContinue,
    'ic_driver' => Assets.images.icDriver,
    'ic_history' => Assets.images.icHistory,
    'ic_info' => Assets.images.icInfo,
    'ic_map' => Assets.images.icMap,
    'ic_moto' => Assets.images.icMoto,
    'ic_route' => Assets.images.icRoute,
    'ic_star' => Assets.images.icStar,
    'ic_user' => Assets.images.icUser,
    _ => throw ArgumentError.value(name, 'name', 'Unknown icon'),
  };

  @override
  Widget build(BuildContext context) => asset.svg(
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
