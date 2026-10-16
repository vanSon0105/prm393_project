import '../../domain/entities/driver.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_remote_datasource.dart';

class DriverRepositoryImpl implements DriverRepository {
  const DriverRepositoryImpl(this._remoteDataSource);

  final DriverRemoteDataSource _remoteDataSource;

  @override
  List<DriverAccountRequest> getAccountRequests() {
    return _remoteDataSource.fetchAccountRequests();
  }

  @override
  List<Driver> getDrivers() {
    return _remoteDataSource.fetchDrivers();
  }
}
