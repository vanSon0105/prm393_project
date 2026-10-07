import 'package:delivery_app/features/detail_delivery/detail_delivery_page.dart';
import 'package:delivery_app/features/map/map_page.dart';
import 'package:delivery_app/features/setting/setting_page.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login/login_page.dart';
import '../features/main/main_page.dart';
import '../features/splash/splash_page.dart';

enum AppRoute {
  splash(rawValue: '/splash'),
  login(rawValue: '/login'),
  map(rawValue: '/map'),
  detailDelivery(rawValue: '/detailDelivery'),
  setting(rawValue: '/setting');

  final String rawValue;

  const AppRoute({required this.rawValue});
}

final GoRouter appRouter = GoRouter(
  navigatorKey: AppNavigate.instance.key,
  initialLocation: AppRoute.splash.rawValue,
  routes: [
    GoRoute(
      path: AppRoute.splash.rawValue,
      name: AppRoute.splash.rawValue,
      builder: (context, state) => const SplashPage(),
    ),

    GoRoute(
      path: AppRoute.login.rawValue,
      name: AppRoute.login.rawValue,
      builder: (context, state) => const LoginPage(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.map.rawValue,
              name: AppRoute.map.rawValue,
              builder: (context, state) => const MapPage(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.detailDelivery.rawValue,
              name: AppRoute.detailDelivery.rawValue,
              builder: (context, state) => const DetailDeliveryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.setting.rawValue,
              name: AppRoute.setting.rawValue,
              builder: (context, state) => const SettingPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
