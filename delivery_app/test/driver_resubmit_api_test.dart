import 'dart:typed_data';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/register/driver_resubmit_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test(
    'rejected driver details and resubmission use leader API contract',
    () async {
      final calls = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add(options);
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: options.method == 'GET'
                      ? {
                          'data': {
                            'driver_id': 8,
                            'phone_number': '0901234567',
                            'vehicle_id': 1,
                            'license_plate': '59A1-12345',
                            'license_plate_expired_date': '2027-12-31',
                            'reason': 'Document is unclear',
                            'driving_license_front_side':
                                'http://bad-ip/image/a.jpg',
                          },
                        }
                      : {
                          'data': {'driver_id': 8, 'active': 0},
                        },
                ),
              );
            },
          ),
        );
      final repository = DriverResubmitRemoteRepository(ApiProvider(dio));

      final request = await repository.getRequest(8);
      expect(request.reason, 'Document is unclear');
      expect(request.vehicleId, 1);
      expect(request.licensePlateExpiredDate, '2027-12-31');
      expect(calls.single.uri.path, '/api/driver/8/register-info');

      await repository.resubmit(
        8,
        DriverResubmitData(
          phoneNumber: '0901234567',
          vehicleId: 2,
          licensePlate: '59A1-67890',
          licensePlateExpiredDate: '2028-12-31',
          documents: {
            'driving_license_front_side': RegisterDocument(
              name: 'new.jpg',
              bytes: Uint8List.fromList([1, 2, 3]),
            ),
          },
        ),
      );
      expect(calls.last.method, 'POST');
      final form = calls.last.data as FormData;
      expect(
        {for (final field in form.fields) field.key: field.value},
        {
          'phone_number': '0901234567',
          'vehicle_id': '2',
          'license_plate': '59A1-67890',
          'license_plate_expired_date': '2028-12-31',
        },
      );
      expect(form.files.single.key, 'driving_license_front_side');
      expect(form.files.single.value.filename, 'new.jpg');
    },
  );
}
