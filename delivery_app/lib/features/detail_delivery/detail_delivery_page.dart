import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';

import '../../core/theme/trip_theme.dart';
import '../app_view_model.dart';
import '../auth/domain/entities/role.dart';
import '../trip/presentation/screens/live_trip_history_page.dart';

class DetailDeliveryPage extends ConsumerWidget {
  const DetailDeliveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appViewModelProvider);
    final profileId = app.profileId;
    return Theme(
      data: createAppTheme(),
      child:
          profileId != null &&
              profileId > 0 &&
              (app.role == Role.customer || app.role == Role.driver)
          ? LiveTripHistoryPage(
              key: ValueKey(profileId),
              profileId: profileId,
              role: app.role!,
              onExit: () => context.go('/map'),
            )
          : Scaffold(
              appBar: AppBar(title: Text(LocaleKeys.trip_history_title.tr())),
              body: Center(child: Text(LocaleKeys.trip_history_sign_in.tr())),
            ),
    );
  }
}
