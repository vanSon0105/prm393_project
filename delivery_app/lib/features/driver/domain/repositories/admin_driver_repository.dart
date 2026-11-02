import '../entities/admin_driver.dart';

abstract class AdminDriverRepository {
  Future<List<AdminDriver>> getDrivers();
}
