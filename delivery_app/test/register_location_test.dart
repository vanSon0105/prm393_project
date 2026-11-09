import 'dart:typed_data';

import 'package:delivery_app/di/repository_module.dart';
import 'package:delivery_app/features/auth/data/models/login_model.dart';
import 'package:delivery_app/features/auth/data/models/register_model.dart';
import 'package:delivery_app/features/auth/data/models/vehicle_type_model.dart';
import 'package:delivery_app/features/auth/data/repositories/login_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_driver_param.dart';
import 'package:delivery_app/features/auth/data/repositories/register_user_param.dart';
import 'package:delivery_app/features/auth/domain/entities/register_account.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/domain/repositories/authentication_repository.dart';
import 'package:delivery_app/features/auth/register/register_view_model.dart';
import 'package:delivery_app/features/location/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService({this.failure});

  final LocationAccessException? failure;
  int requests = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Coordinates> currentCoordinates() async {
    requests++;
    if (failure != null) throw failure!;
    return const Coordinates(10.776889, 106.700806);
  }
}

class _RecordingRepository implements AuthenticationRepository {
  RegisterDriverParam? submitted;

  @override
  Future<RegisterModel> registerDriverAccount(RegisterDriverParam param) async {
    submitted = param;
    return RegisterModel(
      data: RegisterData(
        profileId: 12,
        userName: 'driver_test',
        role: 'DRIVER',
        message: 'Pending',
      ),
    );
  }

  @override
  Future<RegisterModel> registerCustomerAccount(RegisterUserParam param) =>
      throw UnimplementedError();

  @override
  Future<LoginModel> login({required LoginParam param}) =>
      throw UnimplementedError();

  @override
  Future<VehicleTypeModel> getVehicleTypes() => throw UnimplementedError();

  @override
  Future<Role> getRoles() => throw UnimplementedError();
}

RegisterAccountRequest _driverRequest() {
  final document = RegisterDocument(
    name: 'document.jpg',
    bytes: Uint8List.fromList([1, 2, 3]),
  );
  return RegisterAccountRequest(
    fullName: 'Driver Test',
    userName: 'driver_test',
    password: 'secret123',
    phoneNumber: '0901234567',
    role: Role.driver,
    vehicleId: 1,
    licensePlate: '59A1-12345',
    licensePlateExpiredDate: '2027-12-31',
    documents: {
      'driving_license_front_side': document,
      'driving_license_back_side': document,
      'front_side_of_the_identity_card': document,
      'the_back_of_the_identity_card': document,
    },
  );
}

void main() {
  test('driver registration uses current coordinates', () async {
    final location = _FakeLocationService();
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        authenticationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(registerViewModelProvider(Role.driver).notifier)
        .register(_driverRequest());

    expect(location.requests, 1);
    expect(repository.submitted?.latitude, 10.776889);
    expect(repository.submitted?.longitude, 106.700806);
  });

  test('driver registration stops when location is denied', () async {
    final location = _FakeLocationService(
      failure: const LocationAccessException(
        LocationAccessFailure.permissionDenied,
      ),
    );
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        authenticationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(registerViewModelProvider(Role.driver).notifier)
          .register(_driverRequest()),
      throwsA(isA<LocationAccessException>()),
    );
    expect(repository.submitted, isNull);
  });
}
