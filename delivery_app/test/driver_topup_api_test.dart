import 'dart:typed_data';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/driver/data/driver_topup_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test(
    'driver top-up uses bank, create, list, detail and update API',
    () async {
      final calls = <RequestOptions>[];
      final row = {
        'transaction_id': 9,
        'driver_id': 5,
        'driver_name': 'Driver A',
        'balance': 50000.0,
        'active': 0,
        'status': 'REJECTED',
        'image_transaction': 'http://192.168.2.14:8080/image/receipt.jpg',
        'reject_reason': 'Incorrect receipt',
        'time': '2026-11-08 09:30:00',
      };
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add(options);
              final data = switch (options.uri.path) {
                '/api/admin/bank-info' => {
                  'data': {
                    'bank_name': 'Example Bank',
                    'bank_account_number': '123456789',
                    'bank_account_name': 'TEAM',
                    'bank_qr_code': 'qr.png',
                  },
                },
                '/api/driver/5/topup/requests' => [row],
                _ => {'data': row},
              };
              handler.resolve(
                Response(requestOptions: options, statusCode: 200, data: data),
              );
            },
          ),
        );
      final repository = DriverTopupRepository(ApiProvider(dio));

      final bank = await repository.getAdminBank();
      expect(bank.number, '123456789');
      expect(bank.qrUrl, contains('/image/qr.png'));

      await repository.submit(
        driverId: 5,
        amount: 50000,
        fileName: 'receipt.jpg',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(calls[1].uri.path, '/api/driver/topup');
      expect(calls[1].method, 'POST');
      final created = calls[1].data as FormData;
      expect(
        {for (final field in created.fields) field.key: field.value},
        {'driver_id': '5', 'balance': '50000'},
      );
      expect(created.files.single.key, 'image_transaction');

      final requests = await repository.getRequests(5);
      expect(calls[2].uri.path, '/api/driver/5/topup/requests');
      expect(requests.single.status, 'REJECTED');
      expect(requests.single.proofUrl, contains('/image/receipt.jpg'));

      final detail = await repository.getDetail(9);
      expect(calls[3].uri.path, '/api/topup/9');
      expect(detail.rejectReason, 'Incorrect receipt');

      await repository.submit(
        driverId: 5,
        amount: 60000,
        fileName: 'corrected.png',
        imageBytes: Uint8List.fromList([4, 5, 6]),
        requestId: 9,
      );
      expect(calls[4].uri.path, '/api/driver/topup/9/update');
      expect(calls[4].method, 'PUT');
      expect(
        (calls[4].data as FormData).files.single.value.filename,
        'corrected.png',
      );
    },
  );
}
