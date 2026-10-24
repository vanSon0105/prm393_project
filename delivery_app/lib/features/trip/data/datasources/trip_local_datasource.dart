import '../../domain/entities/trip.dart';

/// In-memory sample data; replace this source when persistence is added.
class TripLocalDataSource {
  List<Trip> fetchTrips() => <Trip>[
    Trip(
      code: 'NS2408',
      date: 'Hôm nay, 09:24',
      pickup: '12 Nguyễn Huệ, Quận 1',
      destination: '86 Võ Văn Tần, Quận 3',
      service: 'Giao hàng hóa',
      price: '42.000đ',
      driver: 'Trần Anh',
      plate: '59A1 234.56',
      icon: 'ic_moto',
      status: TripStatus.approaching,
      paid: false,
    ),
    Trip(
      code: 'NS2310',
      date: '03/10/2026 · 18:10',
      pickup: '18 Lê Lợi, Quận 1',
      destination: '210 Nguyễn Trãi, Quận 5',
      service: 'Giao đồ ăn',
      price: '31.000đ',
      driver: 'Phạm Quốc Huy',
      plate: '59P2 418.27',
      icon: 'ic_moto',
    ),
    Trip(
      code: 'NS2297',
      date: '29/09/2026 · 07:45',
      pickup: 'Bệnh viện Chợ Rẫy, Quận 5',
      destination: 'Bình Hưng Hòa, Bình Tân',
      service: 'Vận chuyển chuyên biệt',
      price: '485.000đ',
      driver: 'Lê Minh Tuấn',
      plate: '51D 826.14',
      icon: 'ic_car',
    ),
    Trip(
      code: 'NS2214',
      date: '25/09/2026 · 14:32',
      pickup: 'Pasteur, Quận 3',
      destination: 'Điện Biên Phủ, Bình Thạnh',
      service: 'Giao hàng hóa',
      price: '38.000đ',
      driver: 'Chưa phân công',
      plate: 'Không có tài xế',
      icon: 'ic_route',
      status: TripStatus.cancelled,
      paid: false,
    ),
  ];
}
