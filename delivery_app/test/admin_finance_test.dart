import 'dart:convert';

import 'package:delivery_app/config/environment.dart';
import 'package:delivery_app/data/network/base/provider.dart';
import 'package:delivery_app/features/admin/data/admin_finance_remote_repository.dart';
import 'package:delivery_app/features/admin/domain/entities/admin_finance.dart';
import 'package:delivery_app/routes/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Environment.configFlavor(FlavorValue.dev));

  test('admin finance routes and amount validation', () {
    expect(
      appRouter.namedLocation(AppRoute.adminBankAccount.rawValue),
      '/admin/bank-account',
    );
    expect(
      appRouter.namedLocation(AppRoute.adminTopUpRequests.rawValue),
      '/admin/top-up-requests',
    );
    expect(
      () => DriverTopUpRequest.fromJson({
        'transaction_id': 1,
        'driver_id': 2,
        'driver_name': 'Driver A',
        'balance': 0,
        'status': 'pending',
        'time': '2026-11-03 10:00:00',
      }),
      throwsFormatException,
    );
  });

  test('bank details and top-ups use the server API contract', () async {
    final calls = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls.add(options);
            final data = switch (Uri.parse(options.path).path) {
              '/api/4/bank-info' when options.method == 'GET' => {
                'data': {
                  'bank_name': 'Example Bank',
                  'bank_account_number': '1234567890',
                  'bank_account_name': 'TEAM',
                  'bank_qr_code': '4_bank.png',
                },
              },
              '/api/admin/topup/requests' => [
                {
                  'transaction_id': 7,
                  'driver_id': 5,
                  'driver_name': 'Driver A',
                  'balance': 50000.0,
                  'active': 0,
                  'status': 'PENDING',
                  'image_transaction': '',
                  'reject_reason': '',
                  'time': '2026-11-03 10:00:00',
                },
              ],
              _ => {'data': {}},
            };
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: data),
            );
          },
        ),
      );
    final repository = AdminFinanceRemoteRepository(
      ApiProvider(dio),
      profileId: 4,
    );

    final bank = await repository.getBankAccount();
    expect(bank?.accountNumber, '1234567890');
    expect(bank?.qrCode, '4_bank.png');
    await repository.updateBankAccount(
      const AdminBankAccount(
        bankName: 'Example Bank',
        accountNumber: '1234567890',
        accountHolder: 'TEAM',
        qrBytes: [1, 2, 3],
        qrFileName: 'bank.png',
      ),
    );
    expect(calls[0].uri.path, '/api/4/bank-info');
    expect(calls[1].method, 'POST');
    expect(
      (calls[1].data as FormData).fields
          .singleWhere((field) => field.key == 'bank_account_number')
          .value,
      '1234567890',
    );
    expect((calls[1].data as FormData).files.single.key, 'bank_qr_code');

    final requests = await repository.getTopUpRequests();
    expect(calls[2].uri.path, '/api/admin/topup/requests');
    expect(requests.single.amount, 50000);
    expect(requests.single.status, TopUpStatus.pending);

    await repository.reviewTopUpRequest(requestId: 7, approved: true);
    expect(calls[3].uri.path, '/api/admin/topup/7/review');
    expect(calls[3].method, 'PATCH');
    expect(jsonDecode(calls[3].data as String), {'status': true});

    await repository.reviewTopUpRequest(
      requestId: 7,
      approved: false,
      reason: '  No transfer received  ',
    );
    expect(calls[4].uri.path, '/api/admin/topup/7/review');
    expect(jsonDecode(calls[4].data as String), {
      'status': false,
      'reason': 'No transfer received',
    });
    expect(
      () => repository.reviewTopUpRequest(
        requestId: 7,
        approved: false,
        reason: '  ',
      ),
      throwsArgumentError,
    );
    expect(calls, hasLength(5));
  });
}
