import '../../domain/entities/driver.dart';
import '../models/driver_model.dart';

class DriverRemoteDataSource {
  const DriverRemoteDataSource();

  List<DriverModel> fetchDrivers() {
    return [
      DriverModel(
        id: 'driver-01',
        name: 'Trần Anh',
        phone: '090 123 4567',
        vehicle: 'Honda Air Blade',
        plateNumber: '59A1 234.56',
        rating: 4.96,
        totalTrips: 286,
        status: DriverStatus.available,
        joinedAt: DateTime(2025, 4, 12),
      ),
      DriverModel(
        id: 'driver-02',
        name: 'Lê Hoàng',
        phone: '091 882 1204',
        vehicle: 'Yamaha Janus',
        plateNumber: '59F2 812.04',
        rating: 4.93,
        totalTrips: 241,
        status: DriverStatus.delivering,
        joinedAt: DateTime(2025, 6, 9),
      ),
      DriverModel(
        id: 'driver-03',
        name: 'Phạm Minh',
        phone: '093 560 1890',
        vehicle: 'Honda Wave',
        plateNumber: '50N1 403.28',
        rating: 4.91,
        totalTrips: 198,
        status: DriverStatus.offline,
        joinedAt: DateTime(2025, 9, 18),
      ),
      DriverModel(
        id: 'driver-04',
        name: 'Vũ Nam',
        phone: '098 122 7441',
        vehicle: 'Honda Vision',
        plateNumber: '59P1 731.45',
        rating: 4.89,
        totalTrips: 176,
        status: DriverStatus.available,
        joinedAt: DateTime(2026, 1, 5),
      ),
      DriverModel(
        id: 'driver-05',
        name: 'Hoàng Tuấn',
        phone: '097 638 2100',
        vehicle: 'Yamaha Sirius',
        plateNumber: '51G 462.19',
        rating: 4.87,
        totalTrips: 164,
        status: DriverStatus.delivering,
        joinedAt: DateTime(2026, 2, 14),
      ),
      DriverModel(
        id: 'driver-06',
        name: 'Đặng Khoa',
        phone: '096 472 9021',
        vehicle: 'Honda SH Mode',
        plateNumber: '59C2 086.33',
        rating: 4.85,
        totalTrips: 151,
        status: DriverStatus.available,
        joinedAt: DateTime(2026, 3, 23),
      ),
    ];
  }

  List<DriverAccountRequestModel> fetchAccountRequests() {
    return [
      DriverAccountRequestModel(
        id: 'request-01',
        name: 'Đỗ Quang Huy',
        phone: '090 771 2244',
        vehicleType: 'Xe máy',
        submittedAt: DateTime(2026, 10, 5, 8, 30),
        note: 'Đủ hồ sơ căn cước và giấy đăng ký xe.',
      ),
      DriverAccountRequestModel(
        id: 'request-02',
        name: 'Mai Phương',
        phone: '091 305 8890',
        vehicleType: 'Ô tô',
        submittedAt: DateTime(2026, 10, 5, 9, 15),
        note: 'Chờ xác minh ảnh bằng lái ô tô.',
      ),
      DriverAccountRequestModel(
        id: 'request-03',
        name: 'Khánh Linh',
        phone: '098 612 9091',
        vehicleType: 'Xe máy',
        submittedAt: DateTime(2026, 10, 4, 16, 45),
        note: 'Đăng ký nhận đơn giao hàng trong nội thành.',
      ),
    ];
  }
}
