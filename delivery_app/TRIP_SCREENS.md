# Giao diện chuyến đi — Huy Hoàng

Ba giao diện: lịch sử chuyến đi của khách hàng, chi tiết chuyến đi của khách
hàng và chi tiết thực hiện chuyến đi của tài xế. Đổi vai trò bằng menu góc
trên bên phải. Các chức năng gồm lọc lịch sử, theo dõi chuyến, xác nhận hủy,
xác nhận lấy hàng, xác nhận hoàn tất và đánh giá từ 1 đến 5 sao.

## Chạy thử

Từ thư mục `delivery_app`, dùng Flutter có Dart từ 3.13.5 theo pubspec của nhóm:

```sh
flutter pub get
flutter run -t lib/main_trip_preview.dart
```

Trong app chung, đường dẫn `/detailDelivery` và tab “Chuyến đi” mở phần này.
Nút “Về bản đồ” ở góc trên trái đưa người dùng về `/map`.
Entry point dev/prod, đăng nhập và giao diện admin của nhóm được giữ nguyên.

## Tổ chức code

- `features/trip/domain`: entity bất biến và interface repository.
- `features/trip/data`: datasource dữ liệu mẫu và cài đặt repository.
- `features/trip/presentation/providers`: Riverpod và cập nhật nghiệp vụ.
- `features/trip/presentation/screens`: màn hình và dialog tương tác.
- `features/trip/presentation/widgets`: lịch sử, chi tiết và trình bày trạng thái.
- `di/trip_repository_module.dart`: cung cấp datasource/repository.
- `core/theme/trip_*`: theme riêng của phần chuyến đi.

Dữ liệu chỉ lưu trong bộ nhớ, khởi động lại sẽ trở về dữ liệu mẫu. Chưa gọi
backend, gọi điện, thanh toán hoặc theo dõi vị trí thật.

## Kiểm tra

```sh
flutter test
flutter analyze
```

`test/trip_widget_test.dart` kiểm tra xác nhận hủy, cập nhật hoàn tất giữa hai
vai trò, đánh giá, lọc lịch sử và bố cục ở màn hình hẹp với chữ lớn.
