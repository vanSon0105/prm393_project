import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/trip_theme.dart';
import '../trip/presentation/screens/trip_page.dart';

class DetailDeliveryPage extends StatelessWidget {
  const DetailDeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: createAppTheme(),
      child: TripApp(onExit: () => context.go('/map')),
    );
  }
}
