import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/admin/data/admin_users_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test('admin users API maps each role and driver documents', () async {
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
                data: [
                  {
                    'profile_id': 1,
                    'full_name': 'Driver One',
                    'user_name': 'driver1',
                    'phone_number': '0901000001',
                    'address': 'Hà Nội',
                    'role': 'DRIVER',
                    'driver_documents': {
                      'driving_license_front_url': 'http://server/front.jpg',
                      'driving_license_back_url': '',
                      'identity_card_front_url': '',
                      'identity_card_back_url': '',
                    },
                  },
                  {
                    'profile_id': 2,
                    'full_name': 'Customer One',
                    'user_name': 'customer1',
                    'phone_number': '',
                    'address': '',
                    'role': 'CUSTOMER',
                  },
                  {
                    'profile_id': 3,
                    'full_name': 'Admin One',
                    'user_name': 'admin1',
                    'phone_number': '',
                    'address': '',
                    'role': 'ADMIN',
                  },
                ],
              ),
            );
          },
        ),
      );

    final users = await AdminUsersRepository(ApiProvider(dio)).getUsers();

    expect(request.method, 'GET');
    expect(request.path, endsWith('/api/admin/users'));
    expect(users.map((user) => user.role), ['DRIVER', 'CUSTOMER', 'ADMIN']);
    expect(users.first.username, 'driver1');
    expect(users.first.documents?.licenseFrontUrl, 'http://server/front.jpg');
    expect(users[1].documents, isNull);
    expect(users[2].name, 'Admin One');
  });
}
