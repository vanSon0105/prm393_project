import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/admin/data/admin_dashboard_repository.dart';
import 'package:delivery_app/features/driver/data/datasources/admin_driver_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test('admin dashboard maps database counts and rated drivers', () async {
    late RequestOptions request;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'total_drivers': 5,
                    'approved_drivers': 4,
                    'pending_requests': 1,
                    'top_rated_drivers': [
                      {
                        'driver_id': 6,
                        'full_name': 'Rated Driver',
                        'rating': 4.75,
                        'completed_trips': 8,
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );

    final overview = await AdminDashboardRepository(ApiProvider(dio))
        .getOverview();

    expect(request.method, 'GET');
    expect(request.path, endsWith('/api/admin/dashboard'));
    expect(overview.totalDrivers, 5);
    expect(overview.approvedDrivers, 4);
    expect(overview.pendingRequests, 1);
    expect(overview.topRatedDrivers.single.name, 'Rated Driver');
    expect(overview.topRatedDrivers.single.rating, 4.75);
    expect(overview.topRatedDrivers.single.completedTrips, 8);
  });

  test('empty request response clears the list', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: null),
            );
          },
        ),
      );

    final requests = await AdminDriverRemoteDataSource(ApiProvider(dio))
        .fetchRequests();

    expect(requests, isEmpty);
  });
}
