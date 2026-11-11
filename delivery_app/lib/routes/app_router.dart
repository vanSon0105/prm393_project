import 'package:delivery_app/features/admin/presentation/screens/admin_home_page.dart';
import 'package:delivery_app/features/admin/presentation/screens/admin_bank_account_page.dart';
import 'package:delivery_app/features/admin/presentation/screens/admin_top_up_requests_page.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/register/driver_terms_screen.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_screen.dart';
import 'package:delivery_app/features/auth/register/register_screen.dart';
import 'package:delivery_app/features/detail_delivery/detail_delivery_page.dart';
import 'package:delivery_app/features/driver/presentation/screens/driver_earnings_page.dart';
import 'package:delivery_app/features/driver/presentation/screens/driver_topup_page.dart';
import 'package:delivery_app/features/driver_rating/driver_rating_screen.dart';
import 'package:delivery_app/features/map/map_page.dart';
import 'package:delivery_app/features/payment/trip_payment_screen.dart';
import 'package:delivery_app/features/profile/edit_profile_screen.dart';
import 'package:delivery_app/features/setting/setting_page.dart';
import 'package:delivery_app/features/trip/presentation/screens/active_trip_page.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login/login_page.dart';
import '../features/main/main_page.dart';
import '../features/splash/splash_page.dart';

enum AppRoute {
  splash(rawValue: '/splash'),
  login(rawValue: '/login'),
  register(rawValue: '/register'),
  driverTerms(rawValue: '/driver-terms'),
  driverResubmit(rawValue: '/driver/:driverId/resubmit'),
  admin(rawValue: '/admin'),
  adminBankAccount(rawValue: '/admin/bank-account'),
  adminTopUpRequests(rawValue: '/admin/top-up-requests'),
  driverEarnings(rawValue: '/driver-earnings'),
  driverTopup(rawValue: '/driver/top-up'),
  driverRating(rawValue: '/driver-rating'),
  tripPayment(rawValue: '/trip-payment'),
  editProfile(rawValue: '/edit-profile'),
  activeTrip(rawValue: '/active-trip'),
  map(rawValue: '/map'),
  detailDelivery(rawValue: '/detailDelivery'),
  setting(rawValue: '/setting');

  final String rawValue;

  const AppRoute({required this.rawValue});
}

GoRouter createAppRouter({String? initialLocation}) => GoRouter(
  navigatorKey: AppNavigate.instance.key,
  initialLocation: initialLocation ?? AppRoute.splash.rawValue,
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

    GoRoute(
      path: AppRoute.register.rawValue,
      name: AppRoute.register.rawValue,
      builder: (context, state) {
        final role = state.extra as Role;
        return RegisterScreen(role: role);
      },
    ),
    GoRoute(
      path: AppRoute.driverTerms.rawValue,
      name: AppRoute.driverTerms.rawValue,
      builder: (context, state) => const DriverTermsScreen(),
    ),
    GoRoute(
      path: AppRoute.driverResubmit.rawValue,
      name: AppRoute.driverResubmit.rawValue,
      builder: (context, state) => DriverResubmitScreen(
        driverId: int.parse(state.pathParameters['driverId']!),
      ),
    ),

    GoRoute(
      path: AppRoute.admin.rawValue,
      name: AppRoute.admin.rawValue,
      builder: (context, state) => const AdminHomePage(),
    ),
    GoRoute(
      path: AppRoute.adminBankAccount.rawValue,
      name: AppRoute.adminBankAccount.rawValue,
      builder: (context, state) => const AdminBankAccountPage(),
    ),
    GoRoute(
      path: AppRoute.adminTopUpRequests.rawValue,
      name: AppRoute.adminTopUpRequests.rawValue,
      builder: (context, state) => const AdminTopUpRequestsPage(),
    ),
    GoRoute(
      path: AppRoute.driverRating.rawValue,
      name: AppRoute.driverRating.rawValue,
      builder: (context, state) => const DriverRatingScreen(),
    ),
    GoRoute(
      path: AppRoute.tripPayment.rawValue,
      name: AppRoute.tripPayment.rawValue,
      builder: (context, state) => const TripPaymentScreen(),
    ),
    GoRoute(
      path: AppRoute.editProfile.rawValue,
      name: AppRoute.editProfile.rawValue,
      builder: (context, state) => const EditProfileScreen(),
    ),

    GoRoute(
      path: AppRoute.driverEarnings.rawValue,
      name: AppRoute.driverEarnings.rawValue,
      builder: (context, state) => const DriverEarningsPage(),
    ),
    GoRoute(
      path: AppRoute.driverTopup.rawValue,
      name: AppRoute.driverTopup.rawValue,
      builder: (context, state) => const DriverTopupPage(),
    ),
    GoRoute(
      path: AppRoute.activeTrip.rawValue,
      name: AppRoute.activeTrip.rawValue,
      builder: (context, state) => const ActiveTripPage(),
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

final GoRouter appRouter = createAppRouter();
