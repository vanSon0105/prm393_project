import '../entities/admin_driver.dart';
import '../entities/admin_driver_request.dart';

abstract class AdminDriverRepository {
  Future<List<AdminDriver>> getDrivers();

  Future<List<AdminDriverRequest>> getRequests();

  Future<void> reviewRequest({
    required int driverId,
    required bool approved,
    String reason = '',
  });
}
