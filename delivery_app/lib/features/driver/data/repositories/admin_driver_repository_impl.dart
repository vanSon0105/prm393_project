import '../../domain/entities/admin_driver.dart';
import '../../domain/entities/admin_driver_request.dart';
import '../../domain/repositories/admin_driver_repository.dart';
import '../datasources/admin_driver_remote_datasource.dart';

class AdminDriverRepositoryImpl implements AdminDriverRepository {
  const AdminDriverRepositoryImpl(this._remoteDataSource);

  final AdminDriverRemoteDataSource _remoteDataSource;

  @override
  Future<List<AdminDriver>> getDrivers() => _remoteDataSource.fetchDrivers();

  @override
  Future<List<AdminDriverRequest>> getRequests() =>
      _remoteDataSource.fetchRequests();

  @override
  Future<void> reviewRequest({
    required int driverId,
    required bool approved,
    String reason = '',
  }) => _remoteDataSource.reviewRequest(
    driverId: driverId,
    approved: approved,
    reason: reason,
  );
}
