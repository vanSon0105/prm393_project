import 'dart:typed_data';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/auth/data/repositories/authentication_repository_impl.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/auth/domain/entities/login_status.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test(
    'customer registration sends multipart fields without driver files',
    () async {
      FormData? submitted;
      RequestOptions? sentRequest;
      final dio = Dio(BaseOptions(baseUrl: Environment.baseUrl))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sentRequest = options;
              submitted = options.data as FormData;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'data': {
                      'profile_id': 8,
                      'user_name': 'new_customer',
                      'role': 'CUSTOMER',
                      'message': 'Created',
                    },
                  },
                ),
              );
            },
          ),
        );
      final repository = AuthenticationRepositoryImpl(ApiProvider(dio));

      final result = await repository.registerCustomerAccount(
        RegisterUserParam(
          fullName: 'Nguyen Van A',
          userName: 'new_customer',
          password: 'secret123',
          phoneNumber: '090 123 4567',
        ),
      );

      expect(result.data.profileId, 8);
      expect(result.data.role, 'CUSTOMER');
      expect(sentRequest?.method, 'POST');
      expect(sentRequest?.uri.path, '/api/user/register');
      expect(sentRequest?.contentType, contains('multipart/form-data'));
      expect(Map.fromEntries(submitted!.fields), {
        'full_name': 'Nguyen Van A',
        'user_name': 'new_customer',
        'password': 'secret123',
        'role': 'CUSTOMER',
        'phone_number': '0901234567',
      });
      expect(submitted!.files, isEmpty);
    },
  );

  test('driver registration uploads four documents and login reads both review states', () async {
    FormData? submitted;
    final dio = Dio(BaseOptions(baseUrl: Environment.baseUrl))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.uri.path == '/api/user/register') {
              submitted = options.data as FormData;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'data': {
                      'profile_id': 9,
                      'user_name': 'new_driver',
                      'role': 'DRIVER',
                      'message': 'Pending approval',
                    },
                  },
                ),
              );
              return;
            }
            final body = options.data as String;
            final rejected = body.contains('rejected_driver');
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'profile_id': 9,
                    'user_name': rejected
                        ? 'rejected_driver'
                        : 'approved_driver',
                    'role': 'DRIVER',
                    'status': rejected ? 'REJECTED' : 'APPROVED',
                    'message': rejected ? 'Document is unclear' : 'Welcome',
                  },
                },
              ),
            );
          },
        ),
      );
    final repository = AuthenticationRepositoryImpl(ApiProvider(dio));
    final document = RegisterDocument(
      name: 'document.jpg',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    await repository.registerDriverAccount(
      RegisterDriverParam(
        fullName: 'New Driver',
        userName: 'new_driver',
        password: 'secret123',
        phoneNumber: '0901234567',
        vehicleId: 1,
        licensePlate: '59A1 234.56',
        licensePlateExpiredDate: '2027-12-31',
        documents: {
          'driving_license_front_side': document,
          'driving_license_back_side': document,
          'front_side_of_the_identity_card': document,
          'the_back_of_the_identity_card': document,
        },
      ),
    );

    final fields = Map.fromEntries(submitted!.fields);
    expect(fields['full_name'], 'New Driver');
    expect(fields['role'], 'DRIVER');
    expect(fields['vehicle_id'], '1');
    expect(fields['license_plate'], '59A1 234.56');
    expect(fields['license_plate_expired_date'], '2027-12-31');
    expect(submitted!.files.map((entry) => entry.key).toSet(), {
      'driving_license_front_side',
      'driving_license_back_side',
      'front_side_of_the_identity_card',
      'the_back_of_the_identity_card',
    });

    final approved = await repository.login(
      param: LoginParam(
        userName: 'approved_driver',
        password: 'secret123',
        role: Role.driver,
      ),
    );
    final rejected = await repository.login(
      param: LoginParam(
        userName: 'rejected_driver',
        password: 'secret123',
        role: Role.driver,
      ),
    );
    expect(LoginStatus.valueOf(approved.data!.status!), LoginStatus.approved);
    expect(LoginStatus.valueOf(rejected.data!.status!), LoginStatus.reject);
    expect(rejected.data!.message, 'Document is unclear');
  });
}
