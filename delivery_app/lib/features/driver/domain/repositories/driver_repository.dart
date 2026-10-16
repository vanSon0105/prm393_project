import '../entities/driver.dart';

abstract class DriverRepository {
  List<Driver> getDrivers();

  List<DriverAccountRequest> getAccountRequests();
}
