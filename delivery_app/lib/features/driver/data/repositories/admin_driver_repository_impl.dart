import '../../domain/entities/admin_driver.dart';
import '../../domain/repositories/admin_driver_repository.dart';
import '../datasources/admin_driver_remote_datasource.dart';

class AdminDriverRepositoryImpl implements AdminDriverRepository {
  const AdminDriverRepositoryImpl(this._remoteDataSource);

  final AdminDriverRemoteDataSource _remoteDataSource;

  @override
  Future<List<AdminDriver>> getDrivers() => _remoteDataSource.fetchDrivers();
}
